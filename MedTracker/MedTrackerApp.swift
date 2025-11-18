//
//  MedTrackerApp.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct MedTrackerApp: App {
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
        
        let container = sharedModelContainer
        let asyncDependency: @Sendable () async -> ModelContainer = { @MainActor in
            return container
        }
        AppDependencyManager.shared.add(key: "ModelContainer", dependency: asyncDependency)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
