//
//  ContentView.swift
//  SSC
//
//  Created by Parth Patel on 2026-02-15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
	
	@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
	@State private var showOnboarding = false
	
	var body: some View {
		HomeView()
			.fullScreenCover(isPresented: $showOnboarding) {
				OnboardingView()
			}
			.onAppear {
				if !hasCompletedOnboarding {
					DispatchQueue.main.asyncAfter(deadline: .now()) {
						showOnboarding = true
					}
				}
			}.accessibilityLabel("IntelliGut App Home")
	}
}

#Preview {
	ContentView()
		.modelContainer(for: ScanModel.self, inMemory: true)
		.environment(FoundationModelsManager())
}
