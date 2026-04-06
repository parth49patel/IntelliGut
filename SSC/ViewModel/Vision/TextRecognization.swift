//
//  TextRecognization.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-23.
//

import SwiftUI
import Vision

@Observable
class TextRecognization {
	var observations = [RecognizedTextObservation]()
	var ingredientObservations: String = ""
	var request = RecognizeTextRequest()

	func performOCR(imageData: Data) async throws {
		observations.removeAll()
		let results = try await request.perform(on: imageData)
		observations = results
		ingredientObservations = extractIngredients(from: results)
	}
	
	// MARK: - Main Extraction Logic
	
	/// Extracts ingredients using multiple strategies with fallbacks
	private func extractIngredients(from observations: [RecognizedTextObservation]) -> String {
		let textArray = observations.map { $0.recognizedText }
		let fullText = textArray.joined(separator: " ")
		
		if let ingredients = findIngredientsWithHeader(in: textArray) {
			return cleanAndFormat(ingredients)
		}
		
		if let ingredients = findIngredientsWithContainsHeader(in: textArray) {
			return cleanAndFormat(ingredients)
		}
		
		if let ingredients = findIngredientsByPattern(in: fullText) {
			return cleanAndFormat(ingredients)
		}
		
		return cleanAndFormat(fullText)
	}
		
	/// Strategy 1: Look for "Ingredients:" header (most common)
	private func findIngredientsWithHeader(in textArray: [String]) -> String? {
		guard let headerIndex = textArray.firstIndex(where: { line in
			let lower = line.lowercased()
			return lower.contains("ingredient") && !isForeignLanguage(line)
		}) else {
			return nil
		}
		
		return extractTextAfterHeader(
			from: textArray,
			startingAt: headerIndex,
			headerLine: textArray[headerIndex]
		)
	}
	
	/// Strategy 2: Look for "Contains:" header (alternative format)
	private func findIngredientsWithContainsHeader(in textArray: [String]) -> String? {
		guard let headerIndex = textArray.firstIndex(where: { line in
			line.lowercased().contains("contains:")
		}) else {
			return nil
		}
		
		return extractTextAfterHeader(
			from: textArray,
			startingAt: headerIndex,
			headerLine: textArray[headerIndex]
		)
	}
	
	/// Strategy 3: Pattern matching (comma-separated items)
	private func findIngredientsByPattern(in text: String) -> String? {
		let sentences = text.components(separatedBy: ".")
		
		for sentence in sentences {
			let commaCount = sentence.filter { $0 == "," }.count
			let bulletCount = sentence.filter { $0 == "•" }.count
			
			// If 3+ separators, likely an ingredient list
			if (commaCount + bulletCount) >= 3 {
				return stopAtTerminators(sentence)
			}
		}
		
		return nil
	}
	
	// MARK: - Text Extraction Helpers
	
	/// Extract text after a header line, stopping at terminators
	private func extractTextAfterHeader(
		from textArray: [String],
		startingAt headerIndex: Int,
		headerLine: String
	) -> String? {
		var result = ""
		
		// Get text after colon on the header line
		if let colonIndex = headerLine.firstIndex(of: ":") {
			let afterColon = String(headerLine[headerLine.index(after: colonIndex)...])
			let trimmed = afterColon.trimmingCharacters(in: .whitespacesAndNewlines)
			result = stopAtTerminators(trimmed)
		}
		
		// Process following lines
		if headerIndex + 1 < textArray.count {
			for line in textArray[(headerIndex + 1)...] {
				let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
				
				if isForeignLanguage(trimmed) { break }
				if isTerminatorLine(trimmed) { break }
				
				if !result.isEmpty && !result.hasSuffix(",") {
					result += " "
				}
				
				let toAdd = stopAtTerminators(trimmed)
				result += toAdd
				
				if toAdd.count < trimmed.count { break }
			}
		}
		
		return result.isEmpty ? nil : result
	}
	
	// MARK: - Detection Helpers
	
	/// Detect if line is in French (Canadian bilingual labels)
	private func isForeignLanguage(_ line: String) -> Bool {
		let lower = line.lowercased()
		
		let foreignKeywords = [
			"ingrédients", "contient", "peut contenir",
			"fabriqué", "à base de", "farine de blé",
		]
		
		return foreignKeywords.contains { lower.contains($0) }
	}
	
	/// Check if line contains terminator keywords
	private func isTerminatorLine(_ line: String) -> Bool {
		let lower = line.lowercased()
		
		let terminators = [
			"may contain", "allergen", "nutrition",
			"serving", "calories", "manufactured",
			"distributed", "best before", "use by",
			"net weight", "storage", "warning"
		]
		
		if terminators.contains(where: { lower.contains($0) }) {
			return true
		}
		
		// Check for sentence ending (period followed by capital letter)
		if line.contains(".") {
			let components = line.components(separatedBy: ".")
			if components.count > 1,
			   let firstChar = components[1].trimmingCharacters(in: .whitespaces).first,
			   firstChar.isUppercase {
				return true
			}
		}
		
		return false
	}
	
	/// Truncate text at first terminator keyword
	private func stopAtTerminators(_ text: String) -> String {
		let lower = text.lowercased()
		
		let terminators = [
			"may contain:", "may contain ", "contains:",
			"allergen", "nutrition facts", "nutrition",
			"serving size", "calories", "manufactured",
			"distributed by", "best before", "use by",
			"net weight", "net wt", "storage", "warning"
		]
		
		var earliestIndex = text.count
		
		// Find earliest terminator
		for terminator in terminators {
			if let range = lower.range(of: terminator) {
				let index = lower.distance(from: lower.startIndex, to: range.lowerBound)
				earliestIndex = min(earliestIndex, index)
			}
		}
		
		// Truncate if terminator found
		if earliestIndex < text.count {
			return String(text.prefix(earliestIndex))
				.trimmingCharacters(in: CharacterSet(charactersIn: " ,."))
		}
		
		return text
	}
	
	// MARK: - Cleaning and Formatting
	
	/// Clean and format extracted text into ingredient list
	private func cleanAndFormat(_ text: String) -> String {
		var cleaned = text
		
		let headersToRemove = [
			"ingredients:", "contains:", "ingredients",
			"made with", "made from"
		]
		for header in headersToRemove {
			cleaned = cleaned.replacingOccurrences(
				of: header,
				with: "",
				options: .caseInsensitive
			)
		}
		
		cleaned = cleaned.replacingOccurrences(
			of: "\\(contains [^)]+\\)",
			with: "",
			options: .regularExpression
		)
		
		cleaned = cleaned.replacingOccurrences(
			of: "\\d+%",
			with: "",
			options: .regularExpression
		)
		
		for bullet in ["•", "●", "·"] {
			cleaned = cleaned.replacingOccurrences(of: bullet, with: ",")
		}
		
		cleaned = cleaned.replacingOccurrences(of: ";", with: ",")
		cleaned = cleaned.replacingOccurrences(of: ":", with: "")
		
		cleaned = cleaned.replacingOccurrences(
			of: "\\s+",
			with: " ",
			options: .regularExpression
		)
		
		cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
		cleaned = cleaned.replacingOccurrences(
			of: ",\\s*",
			with: ", ",
			options: .regularExpression
		)
		
		cleaned = cleaned.replacingOccurrences(
			of: ",+",
			with: ",",
			options: .regularExpression
		)
		
		return cleaned
	}
	
	func reset() {
		observations.removeAll()
		ingredientObservations = ""
	}
}

extension RecognizedTextObservation {
	var recognizedText: String {
		topCandidates(1).first?.string ?? ""
	}
}
