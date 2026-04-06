//
//  FoundationModelsManager.swift
//  SSC
//
//  Created by Parth Patel on 2026-01-04.
//

import Foundation
import FoundationModels

@Observable
class FoundationModelsManager {
	
	var notAvailableReason = "Checking for model availability."
	var isModelAvailable: Bool {
		notAvailableReason.isEmpty
	}
	
	init() {
		checkIsAvailable()
	}
	
	func checkIsAvailable() {
		switch SystemLanguageModel.default.availability {
			case .available:
				notAvailableReason = ""
			case .unavailable(.appleIntelligenceNotEnabled):
				notAvailableReason = "Enable Apple Intelligence from System Settings."
			case .unavailable(.deviceNotEligible):
				notAvailableReason = "Apple Intelligence is not available on this device."
			case .unavailable(.modelNotReady):
				notAvailableReason = "Apple Intelligence is either downlaoding or temporarily unavailable. \nPlease ensure that your device has enough battery and is connected to Wi-Fi."
			case .unavailable(let unknwonReason):
				notAvailableReason = "Apple Intelligence Unaviable: \(String(describing: unknwonReason))"
		}
	}
}
