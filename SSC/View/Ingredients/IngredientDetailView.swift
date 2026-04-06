//
//  IngredientDetailView.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-28.
//

import SwiftUI
import SpriteKit
import FoundationModels

struct UnknownIngredientDetailView: View {
	
	let ingredient: String
	private let session = LanguageModelSession()
	
	@State private var response: String = ""
	
	@Environment(FoundationModelsManager.self) var fmManager
	@Environment(\.scenePhase) private var scenePhase
	
    var body: some View {
		ScrollView {
			VStack {
				if response.isEmpty {
					ProgressView()
				} else {
					Text(response)
				}
			}
		}
		.navigationTitle(ingredient.capitalized)
		.onChange(of: scenePhase) { _, newPhase in
			if newPhase == .active {
				fmManager.checkIsAvailable()
			}
		}
		.onAppear {
			generateText()
		}
    }
	
	private func generateText() {
		let prompt = Prompt {
			"""
			Generate some education content on the following ingredient: \(ingredient).
			   You explain how food ingredients behave during digestion.
			   Your explanations are:
			   - Educational and neutral
			   - Non-medical
			   - Non-diagnostic
			   - Calm and factual
			   
			   Do NOT give advice, warnings, or recommendations.
			   Do NOT mention diseases or medical conditions.
			   Do NOT suggest avoiding or consuming anything.
			"""
		}
		Task {
			do {
				response = fmManager.minimizeMarkdown(try await session.respond(to: prompt).content)
			} catch let error as LanguageModelSession.GenerationError {
				switch error {
					case .guardrailViolation(let context):
						response = "Guardrail Violation: \(context.debugDescription)"
					case .decodingFailure(let context):
						response = "Decoding Failure: \(context.debugDescription)"
					case .rateLimited(let context):
						response = "Rate Limit exceeded: \(context.debugDescription)"
					default:
						response = "Other Reason: \(error.localizedDescription)"
				}
				if let failureReason = error.failureReason {
					response += "\n\(failureReason)"
				}
				if let recoverySuggestion = error.recoverySuggestion {
					response += "\n\(recoverySuggestion)"
				}
			} catch {
				response = error.localizedDescription
			}
		}
	}
}
//
//#Preview {
//	NavigationStack {
//		IngredientDetailView(ingredient: IngredientsModel(id: "Maltodextrin", aliases: ["maltodextrin"], info: IngredientInfo(displayName: "Maltodextrin", riskLevel: "Low", summary: "", symptom: "", painTime: ""), simulation: Simulation(targetOrgan: "", visualColor: "", particleType: "", physicsMass: 1.0, reactionEffect: "", audio: AudioData(spawnSound: "", impactSound: ""))))
//	}
//}

/*
 struct IngredientDetailView: View {
	 
	 let ingredient: IngredientsModel
	 @State private var isRunning = true
	 
	 private let scene: BodySimulationScene
	 
	 init(ingredient: IngredientsModel) {
		 self.ingredient = ingredient
		 let scene = BodySimulationScene(size: UIScreen.main.bounds.size)
		 scene.ingredients = [ingredient]
		 scene.focusedOrgan = TargetOrgan(rawValue: ingredient.simulation.targetOrgan)
		 scene.scaleMode = .resizeFill
		 self.scene = scene
	 }
	 
	 var body: some View {
		 ScrollView {
			 VStack {
				 VStack(alignment: .leading) {
					 Text("Also Known As: ")
						 .font(.headline)
					 ForEach(ingredient.aliases, id: \.self) { name in
						 HStack {
							 Circle()
								 .frame(width: 4, height: 4)
							 Text(name.capitalized)
						 }
					 }
				 }
				 .padding()
				 .background(.ultraThinMaterial)
				 .frame(maxWidth: .infinity, alignment: .leading)
				 .clipShape(RoundedRectangle(cornerRadius: 12))
			 
				 SpriteView(scene: scene)
					 .frame(height: 300)
					 .clipShape(RoundedRectangle(cornerRadius: 16))
				 
				 Button(isRunning ? "Pause Simulation" : "Start Simulation") {
					 isRunning.toggle()
					 scene.isPaused = !isRunning
				 }
				 .buttonStyle(.borderedProminent)
			 }
			 .padding(.horizontal)
		 }
		 .navigationTitle(ingredient.info.displayName.capitalized)
	 }
 }

 #Preview {
	 NavigationStack {
		 IngredientDetailView(ingredient: IngredientsModel(id: "Maltodextrin", aliases: ["maltodextrin"], info: IngredientInfo(displayName: "Maltodextrin", riskLevel: "Low", summary: "", symptom: "", painTime: ""), simulation: Simulation(targetOrgan: "", visualColor: "", particleType: "", physicsMass: 1.0, reactionEffect: "", audio: AudioData(spawnSound: "", impactSound: ""))))
	 }
 }

 */
