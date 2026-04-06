//
//  IngredientsModel.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-28.
//

import Foundation
import FoundationModels
import SwiftData

@Model
class IngredientsModel {
	var name: String
	var explanation: String
	var digestion: String
	var digestiveFeel: String
	
	init(name: String, explanation: String, digestion: String, digestiveFeel: String) {
		self.name = name
		self.explanation = explanation
		self.digestion = digestion
		self.digestiveFeel = digestiveFeel
	}
}

@Generable
struct IngredientSummary {
	
	@Guide(description: "Explain the this ingredient in a few sentences.")
	let explanation: String
	
	@Guide(description: "Explain how to digest this ingredient in a few sentences.")
	let digestion: String
	
	@Guide(description: "Describe the digestive experience for this ingredient.")
	let digestiveFeel: String
}
