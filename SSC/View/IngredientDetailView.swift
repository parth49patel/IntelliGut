//
//  KnownIngredientDetailView.swift
//  SSC
//
//  Created by Parth Patel on 2026-01-05.
//

import SwiftUI
import SwiftData
import FoundationModels

struct IngredientDetailView: View {
	
	let ingredient: String
	
	@State private var response: IngredientSummary?
	@State private var isLoading = false
	@State private var session = LanguageModelSession()
	@State private var vm = IngredientsViewModel()
	
	@State private var showError = false
	@State private var errorMessage: String?
		
	@Environment(\.modelContext) private var context
	@Environment(FoundationModelsManager.self) var fmManager
	@Environment(\.scenePhase) private var scenePhase
	
	@Query private var aiIngredientModel: [IngredientsModel]
	
	private var savedSummary: IngredientsModel? {
		aiIngredientModel.first { $0.name.lowercased() == ingredient.lowercased() }
	}
	
	/// Provides a visual cue for the ingredients's nutritional role using a simple keyword-based categorization
	private var ingredientEmoji: String {
		let lower = ingredient.lowercased()
		if lower.contains("sugar") || lower.contains("syrup") {
			return "🍬"
		} else if lower.contains("protein") || lower.contains("whey") {
			return "💪"
		} else if lower.contains("fiber") || lower.contains("chicory") || lower.contains("inulin") {
			return "🌾"
		} else if lower.contains("oil") || lower.contains("fat") {
			return "🫒"
		} else if lower.contains("salt") || lower.contains("sodium") {
			return "🧂"
		} else if lower.contains("vitamin") || lower.contains("mineral") {
			return "💊"
		} else {
			return "🔬"
		}
	}
	
	var body: some View {
		ZStack {
			LinearGradient(
				colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.02)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()
			
			ScrollView {
				VStack(spacing: 24) {
					headerCard
						.accessibilityLabel("Ingredient: \(ingredient.capitalized)")
					
					if fmManager.isModelAvailable {
						if isLoading {
							loadingView
								.accessibilityLabel("Analyzing ingredient")
						} else if response != nil || savedSummary != nil {
							contentCards
								.accessibilityElement(children: .combine)
						} else {
							generateButton
						}
					} else {
						unavailableView
							.accessibilityLabel("Apple Intelligence unavailable: \(fmManager.notAvailableReason)")
					}
				}
				.padding()
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				VStack(spacing: 2) {
					Text(ingredient.capitalized)
						.font(.headline)
					if savedSummary != nil {
						Text("Saved")
							.font(.caption2)
							.foregroundStyle(.secondary)
					}
				}
			}
			
			toolbarContent
		}
		.alert("Generation Failed", isPresented: $showError) {
			Button("Try Again") {
				generateText()
			}
			Button("Cancel", role: .cancel) { }
		} message: {
			Text(errorMessage ?? "An unknown error occured. Please check your internet connection and try again.")
		}
		.onChange(of: scenePhase) { _, newPhase in
			if newPhase == .active {
				fmManager.checkIsAvailable()
			}
		}
		.onAppear {
			if let saved = savedSummary {
				response = IngredientSummary(
					explanation: saved.explanation,
					digestion: saved.digestion,
					digestiveFeel: saved.digestiveFeel
				)
			} else {
				generateText()
			}
		}
	}
	
	// MARK: - Header Card
	@ViewBuilder
	private var headerCard: some View {
		VStack(spacing: 16) {
			// Emoji
			Text(ingredientEmoji)
				.font(.system(size: 60))
			
			// Name
			Text(ingredient.capitalized)
				.font(.title2)
				.fontWeight(.bold)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 24)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
	}
	
	// MARK: - Loading View
	@ViewBuilder
	private var loadingView: some View {
		VStack(spacing: 16) {
			ProgressView()
				.scaleEffect(1.2)
			Text("Analyzing ingredient...")
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity)
		.frame(minHeight: 200)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
	}
	
	// MARK: - Content Cards
	@ViewBuilder
	private var contentCards: some View {
		VStack(spacing: 16) {
			if let explanation = response?.explanation ?? savedSummary?.explanation {
				InfoCard(
					title: "What It Is",
					icon: "info.circle.fill",
					iconColor: .blue,
					content: explanation
				)
			}
			
			if let digestion = response?.digestion ?? savedSummary?.digestion {
				InfoCard(
					title: "How You Digest It",
					icon: "arrow.triangle.2.circlepath",
					iconColor: .green,
					content: digestion
				)
			}
			
			if let feel = response?.digestiveFeel ?? savedSummary?.digestiveFeel {
				InfoCard(
					title: "What It Feels Like",
					icon: "heart.circle.fill",
					iconColor: .pink,
					content: feel
				)
			}
		}
	}
	
	// MARK: - Generate Button
	@ViewBuilder
	private var generateButton: some View {
		Button {
			generateText()
		} label: {
			HStack {
				Image(systemName: "apple.intelligence")
				Text("Generate Information")
			}
			.font(.headline)
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity)
			.padding()
			.background(.blue)
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
	}
	
	// MARK: - Unavailable View
	@ViewBuilder
	private var unavailableView: some View {
		VStack(spacing: 16) {
			Image(systemName: "apple.intelligence.badge.xmark")
				.font(.system(size: 50))
				.foregroundStyle(.secondary)
			
			Text("Apple Intelligence Required")
				.font(.headline)
			
			Text(fmManager.notAvailableReason)
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
	}
	
	// MARK: - Toolbar
	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		if response != nil {
			ToolbarItem(placement: .topBarTrailing) {
				Menu {
					Button {
						generateText()
					} label: {
						Label("Regenerate", systemImage: "arrow.clockwise")
					}
					.disabled(isLoading)
					
					if savedSummary == nil {
						Button {
							saveSummary()
						} label: {
							Label("Save for Offline", systemImage: "square.and.arrow.down")
						}
						.disabled(isLoading || response == nil)
					}
				} label: {
					Image(systemName: "ellipsis")
				}
			}
		}
	}
	
	// MARK: - Functions
	@MainActor
	func generateText() {
		response = nil
		isLoading = true

		let prompt = Prompt {
			"""
			Generate structured educational content for the ingredient: \(ingredient).
			
			- Explain how it behaves during digestion in 1-2 neutral sentences.
			- Do not provide health advice, warnings, or recommendations.
			- Avoid mentioning medical conditions.
			"""
		}
		
		Task {
			do {
				let result = try await session.respond(to: prompt, generating: IngredientSummary.self).content
				response = result
			} catch {
				errorMessage = error.localizedDescription
				showError = true
			}
			isLoading = false
		}
	}
	
	private func saveSummary() {
		guard let response else { return }
		
		if let existing = savedSummary {
			existing.explanation = response.explanation
			existing.digestion = response.digestion
			existing.digestiveFeel = response.digestiveFeel
		} else {
			let summaryModel = IngredientsModel(
				name: ingredient,
				explanation: response.explanation,
				digestion: response.digestion,
				digestiveFeel: response.digestiveFeel
			)
			context.insert(summaryModel)
		}
		try? context.save()
	}
}

// MARK: - Info Card Component
struct InfoCard: View {
	let title: String
	let icon: String
	let iconColor: Color
	let content: String
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 8) {
				Image(systemName: icon)
					.foregroundStyle(iconColor)
				Text(title)
					.font(.headline)
				Spacer()
			}
			
			Text(content)
				.font(.body)
				.foregroundStyle(.primary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.accessibilityElement(children: .combine)
		.accessibilityLabel("\(title): \(content)")
	}
}
