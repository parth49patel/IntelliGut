//
//  IngredientsListView.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-23.
//

import SwiftUI
import SwiftData
import FoundationModels

struct IngredientsListView: View {
	
	@Environment(\.modelContext) private var context
	@Environment(\.dismiss) private var dismiss
	@Environment(FoundationModelsManager.self) var fmManager
	
	@State private var vm = IngredientsViewModel()
	@State private var showItemNameAlert = false
	@State private var itemName = ""
	@State private var isEditingIngredients = false
	@State private var showAddIngredientAlert = false
	@State private var isSaved = false
	
	let imageData: Data?
	let savedScan: ScanModel?
	
	/// Creates an ingredients list view.
	///  - Parameters:
	///  		- imageData: Raw image data from a newly scanned label.
	///  		- savedScan: Load existing data from a previous scan.
	init(imageData: Data? = nil, savedScan: ScanModel? = nil) {
		self.imageData = imageData
		self.savedScan = savedScan
		if let saved = savedScan {
			_itemName = State(initialValue: saved.itemName)
		}
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				GutPredictionCard(
					prediction: vm.gutPrediction,
					isLoading: vm.isLoadingPrediction
				)
				.accessibilityLabel(vm.gutPrediction?.prediction ?? "Loading gut prediction")
				.accessibilityHint("Shows digestive risk level")
				
				if fmManager.isModelAvailable {
					SummarySection(
						summary: vm.response,
						savedSummary: savedScan?.summary,
						isLoading: vm.isLoadingSummary,
						onGenerate: {
							vm.generateSummary(isAvailable: fmManager.isModelAvailable)
							vm.generateGutPrediction(isAvailable: fmManager.isModelAvailable)
						}
					)
					.accessibilityLabel(vm.response?.overview ?? "Loading summary")
				}
				IngredientsCard(
					ingredients: $vm.ingredients,
					isEditing: $isEditingIngredients,
					onEdit: { vm.startEditingIngredient($0) },
					onDelete: { vm.deleteIngredient($0, savedScan: savedScan, context: context) },
					onAdd: { showAddIngredientAlert = true },
					onRegenerate: {
						isEditingIngredients = false
						vm.regenerateAfterEdit(isAvailable: fmManager.isModelAvailable)
					}
				)
				.accessibilityElement(children: .contain)
			}
			.padding()
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar { toolbarContent }
		
			// MARK: - Alerts
		.alert("Save Scan", isPresented: $showItemNameAlert) {
			TextField("Item Name", text: $itemName)
			Button("Save") {
				vm.saveNewScan(name: itemName, context: context)
				isSaved = true
			}
			.disabled(itemName.isEmpty)
			Button("Cancel", role: .cancel) { }
		}
		.alert("Add Ingredient", isPresented: $showAddIngredientAlert) {
			TextField("Ingredient Name", text: $vm.newIngredientName)
			Button("Add") {
				vm.addIngredient(savedScan: savedScan, context: savedScan != nil ? context : nil)
			}
			.disabled(vm.newIngredientName.isEmpty)
			Button("Cancel", role: .cancel) { vm.newIngredientName = "" }
		}
		.alert("Edit Ingredient", isPresented: .constant(vm.ingredientToEdit != nil)) {
			TextField("Name", text: $vm.editedIngredientName)
			Button("Save") {
				vm.saveEditedIngredient(savedScan: savedScan, context: savedScan != nil ? context : nil)
			}
			.disabled(vm.editedIngredientName.isEmpty)
			Button("Cancel", role: .cancel) { vm.ingredientToEdit = nil }
		}
		.task {
			if savedScan == nil && fmManager.isModelAvailable {
				vm.isLoadingSummary = true
				vm.isLoadingPrediction = true
			}
			await vm.load(imageData: imageData, savedScan: savedScan)
			if savedScan == nil && vm.ingredients.isEmpty {
				vm.isLoadingSummary = false
				vm.isLoadingPrediction = false
			}
			if savedScan == nil && !vm.hasGeneratedContent {
				try? await Task.sleep(for: .milliseconds(500))
				vm.generateAllContent(isModelAvailable: fmManager.isModelAvailable)
			}
			UIAccessibility.post(notification: .screenChanged, argument: "Loading scan results")
		}
	}
	
	// MARK: - Toolbar
	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .principal) {
			VStack(spacing: 2) {
				Text(itemName.isEmpty ? "Scan Results" : itemName)
					.font(.headline)
				if !vm.ingredients.isEmpty {
					Text("\(vm.ingredients.count) ingredients")
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
			}
		}
		
		ToolbarItem(placement: .topBarTrailing) {
			if savedScan == nil {
				Button("Save") { showItemNameAlert = true }
					.disabled(vm.ingredients.isEmpty || isSaved)
			} else {
				Menu {
					Button {
						vm.regenerateAll(
							savedScan: savedScan,
							context: context,
							isAvailable: fmManager.isModelAvailable
						)
					} label: {
						Label("Regenerate Analysis", systemImage: "arrow.clockwise")
					}
					
					Divider()
					
					Button(role: .destructive) {
						if let savedScan {
							context.delete(savedScan)
							try? context.save()
							dismiss()
						}
					} label: {
						Label("Delete Scan", systemImage: "trash")
					}
				} label: {
					Image(systemName: "ellipsis")
				}
			}
		}
	}
}

	// MARK: - Gut Prediction Card
struct GutPredictionCard: View {
	let prediction: GutPrediction?
	let isLoading: Bool
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Label("GUT CHECK", systemImage: "heart.text.square.fill")
					.foregroundStyle(.red)
					.font(.headline)
			
			if isLoading {
				loadingView
			} else if let prediction{
				predictionView(prediction)
			}
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
	}
	
	private var loadingView: some View {
		VStack(spacing: 12) {
			ProgressView()
			Text("Analyzing...")
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, minHeight: 100)
	}
	
	private func predictionView(_ prediction: GutPrediction) -> some View {
		VStack(spacing: 16) {
			StatusBadge(prediction: prediction)
			
			if !prediction.triggers.isEmpty {
				TriggersCard(triggers: prediction.triggers)
			}
			
			TipCard(tip: prediction.tip)
		}
	}
}

	// MARK: - Summary Section
struct SummarySection: View {
	let summary: GeneralSummary?
	let savedSummary: GeneralSummaryModel?
	let isLoading: Bool
	let onGenerate: () -> Void
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Label("SUMMARY", systemImage: "doc.text.fill")
				.font(.headline)
				.foregroundStyle(.blue)
			
			if isLoading {
				loadingView
			} else if let s = summary {
				summaryContent(s.overview, s.digestionProcess, s.complexity)
			} else if let s = savedSummary {
				summaryContent(s.overview, s.digestionProcess, s.complexity)
			} else {
				failedView
			}
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
	}
	
	private var loadingView: some View {
		VStack(spacing: 12) {
			ProgressView()
			Text("Generating...")
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, minHeight: 100)
	}
	
	private var failedView: some View {
		VStack(spacing: 12) {
			Image(systemName: "exclamationmark.triangle")
				.font(.system(size: 40))
				.foregroundStyle(.orange)
			
			Text("Unable to Generate Summary")
				.font(.headline)
			
			Button("Generate Again") {
				onGenerate()
			}
			.buttonStyle(.borderedProminent)
		}
		.frame(maxWidth: .infinity)
		.padding()
	}
	
	private func summaryContent(
		_ overview: String,
		_ digestion: String,
		_ complexity: String
	) -> some View {
		VStack(spacing: 12) {
			SummaryCard(icon: "info.circle.fill", title: "Overview", content: overview, color: .blue)
			SummaryCard(icon: "arrow.triangle.2.circlepath", title: "Digestion", content: digestion, color: .green)
			SummaryCard(icon: "chart.bar.fill", title: "Complexity", content: complexity, color: .purple)
		}
	}
}

	// MARK: - Status Badge
struct StatusBadge: View {
	let prediction: GutPrediction
	
	var body: some View {
		let (color, icon, text) = statusInfo
		HStack(spacing: 12) {
			Image(systemName: icon).font(.title2).foregroundStyle(color)
			Text(text).font(.title3).fontWeight(.bold).foregroundStyle(color)
		}
		.padding(.horizontal, 24).padding(.vertical, 16)
		.background(color.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 1))
	}
	
	private var statusInfo: (Color, String, String) {
		let lower = prediction.prediction.lowercased()
		if lower.contains("gut friendly") {
			return (.green, "checkmark.shield.fill", "GUT FRIENDLY")
		} else if lower.contains("moderate risk") {
			return (.orange, "exclamationmark.triangle.fill", "MODERATE RISK")
		} else if lower.contains("high risk") {
			return (.red, "xmark.shield.fill", "HIGH RISK")
		}
		return (.blue, "info.circle.fill", "ANALYZED")
	}
}

	// MARK: - Triggers & Tip
struct TriggersCard: View {
	let triggers: [String]
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Label("Potential Triggers:", systemImage: "exclamationmark.magnifyingglass")
				.foregroundStyle(.orange).font(.subheadline)
			ForEach(triggers, id: \.self) { trigger in
				HStack {
					Circle().fill(.orange).frame(width: 6, height: 6)
					Text(trigger.capitalized).font(.subheadline)
				}
				.padding(.leading, 8)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding().background(.orange.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
	}
}

struct TipCard: View {
	let tip: String
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "sparkles").foregroundStyle(.blue).font(.title3)
			VStack(alignment: .leading) {
				Text("Quick Tip").font(.caption).foregroundStyle(.blue).fontWeight(.bold)
				Text(tip).font(.subheadline)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding().background(.blue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
	}
}

struct SummaryCard: View {
	let icon: String, title: String, content: String, color: Color
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 6) {
				Image(systemName: icon).foregroundStyle(color).font(.caption)
				Text(title).font(.subheadline).fontWeight(.medium)
			}
			Text(content).font(.body)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding().background(color.opacity(0.05))
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
}

	// MARK: - Ingredients Card
struct IngredientsCard: View {
	@Binding var ingredients: [String]
	@Binding var isEditing: Bool
	let onEdit: (String) -> Void
	let onDelete: (String) -> Void
	let onAdd: () -> Void
	let onRegenerate: () -> Void
	
	var body: some View {
		VStack(spacing: 16) {
			HStack {
				Label("INGREDIENTS", systemImage: "list.bullet.circle.fill")
					.font(.headline).foregroundStyle(.secondary)
				Text("\(ingredients.count)").font(.caption).foregroundStyle(.white)
					.padding(.horizontal, 8).padding(.vertical, 2).background(.green).clipShape(Capsule())
				Spacer()
				if isEditing {
					Button { onAdd() } label: {
						Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
					}
				}
				Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
					.font(.subheadline).fontWeight(.medium)
			}
			
			Divider()
			
			if ingredients.isEmpty {
				ContentUnavailableView("No ingredients detected", systemImage: "doc.text.magnifyingglass")
					.padding()
					.accessibilityLabel("No ingredients detected")
			} else {
				ForEach(ingredients, id: \.self) { ingredient in
					HStack(spacing: 12) {
						Circle().fill(.green).frame(width: 8, height: 8)
						
						if isEditing {
							Text(ingredient.capitalized).font(.body)
							Spacer()
							Button { onEdit(ingredient) } label: {
								Image(systemName: "pencil").font(.title3).foregroundStyle(.blue)
							}
							Button { withAnimation { onDelete(ingredient) } } label: {
								Image(systemName: "trash").font(.title3).foregroundStyle(.red)
							}
						} else {
							NavigationLink(destination: IngredientDetailView(ingredient: ingredient)) {
								Text(ingredient.capitalized).font(.body).foregroundStyle(.primary)
								Spacer()
								Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
							}
						}
					}
					.padding(.vertical, 12)
					.accessibilityLabel(ingredient.capitalized)
					.accessibilityHint(isEditing ? "Double tap to edit" : "Double tap to view details")
				}
			}
		}
		.padding().background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.shadow(color: .black.opacity(0.05), radius: 10, y: 5)
	}
}

extension SavedGutPrediction {
	func toGutPrediction() -> GutPrediction {
		GutPrediction(prediction: self.prediction, triggers: self.triggers, tip: self.tip)
	}
}
