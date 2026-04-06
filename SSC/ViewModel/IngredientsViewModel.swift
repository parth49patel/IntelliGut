//
//  IngredientsViewModel.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-27.
//

import SwiftUI
import SwiftData
import FoundationModels

@Observable
class IngredientsViewModel {
	
	// MARK: Dependencies
	private var textRecognition = TextRecognization()
	private var session = LanguageModelSession()
	
	// MARK: Data Model
	var ingredients: [String] = []
	var response: GeneralSummary?
	var gutPrediction: GutPrediction?
	
	// MARK: UI State
	var isLoadingSummary = false
	var isLoadingPrediction = false
	var hasGeneratedContent = false
	var predictionRetryCount = 0
	var summaryRetryCount = 0
	
	// MARK: Error Handling
	var showError = false
	var errorMessage: String?
	
	// MARK: Editing State
	var newIngredientName = ""
	var ingredientToEdit: String?
	var editedIngredientName = ""
	
	private let maxRetries = 2
	
	// MARK: - Initialization & Loading
	
	/// Loads ingredients from an existing scan OR performs OCR on new image data
	func load(imageData: Data?, savedScan: ScanModel?) async {
		if let savedScan {
			self.ingredients = savedScan.ingredients
			if let savedPred = savedScan.gutPrediction {
				self.gutPrediction = savedPred.toGutPrediction()
			}
			if let savedSum = savedScan.summary {
				self.response = GeneralSummary(
					overview: savedSum.overview,
					digestionProcess: savedSum.digestionProcess,
					complexity: savedSum.complexity
				)
			}
			self.hasGeneratedContent = true
		} else if let imageData {
			do {
				try await textRecognition.performOCR(imageData: imageData)
				parseIngredients(from: textRecognition.ingredientObservations)
			} catch {
				self.ingredients = []
				self.errorMessage = "Failed to recognize ingredients. Please try a different image."
				self.showError = true
			}
		}
	}
	
	// MARK: - AI Generation
	
	@MainActor
	func generateAllContent(isModelAvailable: Bool) {
		guard !ingredients.isEmpty else { return }
		
		if hasGeneratedContent {
			predictionRetryCount = 0
			summaryRetryCount = 0
		}
		generateSummary(isAvailable: isModelAvailable)
		Task {
			try? await Task.sleep(for: .milliseconds(300))
			generateGutPrediction(isAvailable: isModelAvailable)
		}
		hasGeneratedContent = true
	}
	
	@MainActor
	func generateGutPrediction(isAvailable: Bool) {
		guard !ingredients.isEmpty, isAvailable, predictionRetryCount < maxRetries else { return }
		isLoadingPrediction = true
		
		let prompt = Prompt {
			"""
			Analyze the following ingredients for digestive sensitivity: \(ingredients.joined(separator: ", ")).
			Identify triggers like Sugar Alcohols, High Fiber, Lactose, Gluten, or Artificial Sweeteners.
			
			Rate the safety using EXACTLY one of these terms:
			1. "Gut Friendly"
			2. "Moderate Risk"
			3. "High Risk"
			"""
		}
		
		Task {
			do {
				gutPrediction = try await session.respond(to: prompt, generating: GutPrediction.self).content
				predictionRetryCount = 0
				isLoadingPrediction = false
			} catch {
				if predictionRetryCount < maxRetries {
					predictionRetryCount += 1
					try? await Task.sleep(for: .milliseconds(800))
					generateGutPrediction(isAvailable: isAvailable)
				} else {
					isLoadingPrediction = false
					if response == nil {
						self.errorMessage = "Failed to anayze ingredients. Please check you connection."
						self.showError = true
					}
				}
			}
		}
	}
	
	@MainActor
	func generateSummary(isAvailable: Bool) {
		guard !ingredients.isEmpty, isAvailable, summaryRetryCount < maxRetries else { return }
		isLoadingSummary = true
		
		let prompt = Prompt {
			"Generate neutral educational summary for: \(ingredients.joined(separator: ", ")). Explain interaction with organs. No medical advice."
		}
		
		Task {
			do {
				response = try await session.respond(to: prompt, generating: GeneralSummary.self).content
				summaryRetryCount = 0
				isLoadingSummary = false
			} catch {
				if summaryRetryCount < maxRetries {
					summaryRetryCount += 1
					try? await Task.sleep(for: .milliseconds(800))
					generateSummary(isAvailable: isAvailable)
				} else {
					isLoadingSummary = false
					if gutPrediction == nil {
						self.errorMessage = "Failed to generate summary. Please check your connection."
						self.showError = true
					}
				}
			}
		}
	}
	
	@MainActor
	func regenerateAll(savedScan: ScanModel?, context: ModelContext, isAvailable: Bool) {
		guard !ingredients.isEmpty else { return }
		
		response = nil
		gutPrediction = nil
		hasGeneratedContent = false
		
		generateAllContent(isModelAvailable: isAvailable)
		
		if let savedScan {
			Task {
				while isLoadingSummary || isLoadingPrediction {
					try? await Task.sleep(for: .milliseconds(200))
				}
				
				if let response {
					savedScan.summary = GeneralSummaryModel(
						overview: response.overview,
						digestionProcess: response.digestionProcess,
						complexity: response.complexity
					)
				}
				if let gutPrediction {
					savedScan.gutPrediction = SavedGutPrediction(from: gutPrediction)
				}
				try? context.save()
			}
		}
	}
	
	// MARK: - Ingredient Management
	
	func addIngredient(savedScan: ScanModel?, context: ModelContext?) {
		let trimmed = newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		if !trimmed.isEmpty, !ingredients.contains(trimmed) {
			ingredients.append(trimmed)
			if let savedScan, let context {
				savedScan.ingredients = ingredients
				try? context.save()
			}
		}
		newIngredientName = ""
	}
	
	func startEditingIngredient(_ ingredient: String) {
		ingredientToEdit = ingredient
		editedIngredientName = ingredient
	}
	
	func saveEditedIngredient(savedScan: ScanModel?, context: ModelContext?) {
		guard let oldName = ingredientToEdit else { return }
		let newName = editedIngredientName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		
		if !newName.isEmpty, let index = ingredients.firstIndex(of: oldName) {
			ingredients[index] = newName
			if let savedScan, let context {
				savedScan.ingredients = ingredients
				try? context.save()
			}
		}
		ingredientToEdit = nil
	}
	
	func deleteIngredient(_ ingredient: String, savedScan: ScanModel?, context: ModelContext?) {
		ingredients.removeAll { $0 == ingredient }
		if let savedScan, let context {
			savedScan.ingredients = ingredients
			try? context.save()
		}
	}
	
	func regenerateAfterEdit(isAvailable: Bool) {
		response = nil
		gutPrediction = nil
		generateAllContent(isModelAvailable: isAvailable)
	}
	
	// MARK: - Persistence
	
	func saveNewScan(name: String, context: ModelContext) {
		let summaryModel = response.map { GeneralSummaryModel(overview: $0.overview, digestionProcess: $0.digestionProcess, complexity: $0.complexity) }
		let predictionModel = gutPrediction.map { SavedGutPrediction(from: $0) }
		
		let scan = ScanModel(itemName: name, ingredients: ingredients)
		scan.summary = summaryModel
		scan.gutPrediction = predictionModel
		
		context.insert(scan)
		try? context.save()
	}

	// MARK: - Helper: Extract Ingredients
	func parseIngredients(from text: String) {
		ingredients = text
			.lowercased()
			.replacingOccurrences(of: "ingredients:", with: "")
			.replacingOccurrences(of: "•", with: ",")
			.replacingOccurrences(of: "●", with: ",")
			.replacingOccurrences(of: "·", with: ",")
			.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
			.replacingOccurrences(of: " and/or ", with: ", ")
			.replacingOccurrences(of: " or ", with: ", ")
			.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
			.map { ingredient in
				var clean = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
				if clean.hasPrefix("and ") { clean = String(clean.dropFirst(4)) }
				if clean.hasSuffix(".") { clean = String(clean.dropLast()) }
				return clean
			}
			.filter { !$0.isEmpty }
			.reduce(into: [String]()) { result, ingredient in
				if !result.contains(ingredient) { result.append(ingredient) }
			}
	}
}
