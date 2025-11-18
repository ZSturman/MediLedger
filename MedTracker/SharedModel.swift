//
//  SharedModel.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import Foundation
import SwiftData

public let sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([Med.self, MedLog.self])
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
