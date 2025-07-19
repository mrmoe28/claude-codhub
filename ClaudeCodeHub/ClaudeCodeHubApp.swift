//
//  ClaudeCodeHubApp.swift
//  ClaudeCodeHub
//
//  Created by Edward Harrison on 7/18/25.
//

import SwiftUI
import SwiftData

@main
struct ClaudeCodeHubApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            ErrorEntry.self,
            KnownError.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
