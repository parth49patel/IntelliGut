//
//  ScanModel.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-30.
//

import Foundation
import SwiftData
import FoundationModels

// MARK: - Scanned Item
@Model
class ScanModel: Identifiable {
	
	var itemName: String
	var ingredients: [String]
	var dateSaved: Date = Date.now
	
	@Relationship(deleteRule: .cascade)
	var summary: GeneralSummaryModel?
	
	@Relationship(deleteRule: .cascade)
	var gutPrediction: SavedGutPrediction?
	
	init(itemName: String, ingredients: [String]) {
		self.itemName = itemName
		self.ingredients = ingredients
	}
}

//MARK: - General Summary of Scanned Item
@Model
class GeneralSummaryModel {
	var overview: String
	var digestionProcess: String
	var complexity: String
	
	init(overview: String, digestionProcess: String, complexity: String) {
		self.overview = overview
		self.digestionProcess = digestionProcess
		self.complexity = complexity
	}
}

@Generable
struct GeneralSummary {
	
	@Guide(description: "Provide a short, neutral overview (1-2 sentences) describing what it is generally like to consume a food item made from the given ingredients.")
	var overview: String
	
	@Guide(description: "Describe, in general terms, how the ingredients are typically processed during digestion.")
	var digestionProcess: String
	
	@Guide(description: "Describe the overall complexity of the ingredient list in terms of variety and formulation, using neutral language. Do not judge the food as good or bad.")
	var complexity: String
}

//MARK: - Gut Prediction of Scanned Item
@Model
class SavedGutPrediction {
	var prediction: String
	var triggers: [String]
	var tip: String
	var timestamp: Date
	
	init(from gutPrediction: GutPrediction) {
		self.prediction = gutPrediction.prediction
		self.triggers = gutPrediction.triggers
		self.tip = gutPrediction.tip
		self.timestamp = Date.now
	}
}

@Generable
struct GutPrediction {
	
	@Guide(description: "Rate digestive comfort level using EXACTLY one of these three phrases: 'Gut Friendly' (for minimal triggers), 'Moderate Risk' (for 1-2 mild triggers), or 'High Risk' (for 3+ serious triggers). Include this exact phrase in your response, followed by a brief reason why in one sentence.")
	var prediction: String
	
	@Guide(description: "List 1-3 specific ingredients that may cause digestive discomfort for sensitive stomachs. If none are concerning, return empty array.")
	var triggers: [String]
	
	@Guide(description: "One actionable tip for consuming this product safely. Examples: 'Eat with food', 'Drink extra water', 'Start with small portion', 'Enjoy without worry'. Keep it brief and practical.")
	var tip: String
}
