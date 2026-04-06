//
//  HomeView.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-23.
//

import SwiftUI
import SwiftData

struct HomeView: View {
	
	@State private var navPath = NavigationPath()
	@State var showCamera: Bool = false
	@State private var imageData: Data? = nil
	
	@Query(sort: \ScanModel.dateSaved, order: .reverse)
	private var scannedItems: [ScanModel]
	
	var body: some View {
		NavigationStack(path: $navPath) {
			ZStack {
				Color(uiColor: .systemGroupedBackground)
					.ignoresSafeArea()
				
				if scannedItems.isEmpty {
					emptyState
				} else {
					scansList
				}
			}
			.navigationTitle("My Scans")
			.navigationDestination(for: Route.self) { route in
				switch route {
					case .ingredients(let data):
						IngredientsListView(imageData: data)
				}
			}
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showCamera = true
					} label: {
						Image(systemName: "camera.viewfinder")
					}
					.accessibilityLabel("Scan new item")
					.accessibilityHint("Opens camera to scan ingredient label")
				}
			}
		}
		.fullScreenCover(isPresented: $showCamera) {
			CameraView(
				showCamera: $showCamera,
				imageData: $imageData
			)
		}
		.onChange(of: imageData) { _, newValue in
			if let data = newValue {
				navPath.append(Route.ingredients(data))
			}
		}
	}
	
	// MARK: - Empty State
	
	@ViewBuilder
	private var emptyState: some View {
		VStack(spacing: 24) {
			Button {
				showCamera = true
			} label: {
				ZStack {
					Circle()
						.fill(.accent.opacity(0.1))
						.frame(width: 140, height: 140)
					
					Image(systemName: "camera.viewfinder")
						.font(.system(size: 60))
						.foregroundStyle(.accent)
				}
			}
			.accessibilityLabel("Open Camera")
			.accessibilityHint("Starts scanning a real ingredient label.")
			
			VStack(spacing: 12) {
				Text("Start Your Gut Check")
					.font(.title2)
					.fontWeight(.bold)
				
				Text("Scan an ingredient label to see if\nit's safe for your stomach.")
					.font(.body)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal)
			}
			.accessibilityElement(children: .combine)
			
			CapsuleButton(background: .blue.opacity(0.7)) {
				imageData = UIImage(named: "sampleLabel")?.jpegData(compressionQuality: 0.8)
				showCamera = false
			} label: {
				Label("Use Sample Image", systemImage: "photo.fill")
					.foregroundStyle(.white)
			}
			.accessibilityLabel("Use Sample Image")
			.accessibilityHint("Tests the app using a pre-loaded ingredient label.")
		}
		.padding()
	}
	
	// MARK: - Scans List
	
	@ViewBuilder
	private var scansList: some View {
		ScrollView {
			LazyVStack(spacing: 16) {
				ForEach(scannedItems) { item in
					ScanCard(scan: item, navPath: $navPath)
				}
			}
			.padding()
		}
	}
}

// MARK: - Scan Card Component

struct ScanCard: View {
	let scan: ScanModel
	@Binding var navPath: NavigationPath
	
	private var status: (Color, String) {
		guard let prediction = scan.gutPrediction?.prediction.lowercased() else {
			return (.blue, "Analyzed")
		}
		
		if prediction.contains("gut friendly") {
			return (.green, "Gut Friendly")
		}
		else if prediction.contains("moderate risk") {
			return (.orange, "Moderate Risk")
		}
		else if prediction.contains("high risk") {
			return (.red, "High Risk")
		}
		else {
			return (.blue, "Analyzed")
		}
	}
	
	var body: some View {
		NavigationLink(destination: IngredientsListView(savedScan: scan)) {
			HStack(spacing: 0) {
				Rectangle()
					.fill(status.0)
					.frame(width: 8)
				
				HStack(spacing: 16) {
					VStack(alignment: .leading, spacing: 8) {
						
						Text(scan.itemName)
							.font(.headline)
							.foregroundStyle(.primary)
							.lineLimit(1)
						
						Text(status.1.uppercased())
							.font(.caption)
							.fontWeight(.bold)
							.foregroundStyle(status.0)
						
						Text("\(scan.ingredients.count) ingredients")
							.font(.caption)
							.fontWeight(.medium)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
					
					Image(systemName: "chevron.right")
						.font(.caption)
						.fontWeight(.bold)
						.foregroundStyle(.tertiary)
				}
				.padding(16)
			}
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
		.buttonStyle(.plain)
		.accessibilityAddTraits(.isButton)
	}
}

/// Represents the navigation route used to naigate from a captured image to its ingredients list screen.
enum Route: Hashable {
	// Data: The image data passed to the ingredients list view.
	case ingredients(Data)
}

#Preview {
	HomeView()
		.modelContainer(for: ScanModel.self, inMemory: true)
		.environment(FoundationModelsManager())
}
