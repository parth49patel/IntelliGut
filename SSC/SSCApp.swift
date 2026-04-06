//
//  SSCApp.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-19.
//

import SwiftUI
import SwiftData

@main
struct SSCApp: App {
   
	var sharedModelContainer: ModelContainer = {
		let schema = Schema([ScanModel.self, IngredientsModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

	@State private var fmManager = FoundationModelsManager()
	
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
		.environment(fmManager)
    }
}
