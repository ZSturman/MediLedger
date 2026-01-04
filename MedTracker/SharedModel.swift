//
//  SharedModel.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import Foundation
import SwiftData

// MARK: - App Group Identifier
public let appGroupIdentifier = "group.zacharysturman.MediLedger"

// MARK: - Shared UserDefaults for Widget Communication
public var sharedUserDefaults: UserDefaults? {
    UserDefaults(suiteName: appGroupIdentifier)
}

// MARK: - Pending Medication Update (Optimistic Updates)
/// Stores pending updates to medication state for optimistic widget rendering
public struct PendingMedicationUpdate: Codable {
    public let medicationId: String
    public let updatedPillsRemaining: Double
    public let updatedTotalMgRemaining: Double
    public let timestamp: Date
    
    public init(medicationId: String, updatedPillsRemaining: Double, updatedTotalMgRemaining: Double, timestamp: Date = Date()) {
        self.medicationId = medicationId
        self.updatedPillsRemaining = updatedPillsRemaining
        self.updatedTotalMgRemaining = updatedTotalMgRemaining
        self.timestamp = timestamp
    }
    
    /// Check if this update is still valid (within 5 seconds)
    public var isValid: Bool {
        Date().timeIntervalSince(timestamp) < 5.0
    }
}

// MARK: - Pending Update Storage Keys
private let pendingUpdateKey = "PendingMedicationUpdate"

public extension UserDefaults {
    /// Save a pending medication update for optimistic widget rendering
    func savePendingUpdate(_ update: PendingMedicationUpdate) {
        if let data = try? JSONEncoder().encode(update) {
            set(data, forKey: pendingUpdateKey)
        }
    }
    
    /// Retrieve the pending medication update if it exists and is still valid
    func getPendingUpdate() -> PendingMedicationUpdate? {
        guard let data = data(forKey: pendingUpdateKey),
              let update = try? JSONDecoder().decode(PendingMedicationUpdate.self, from: data),
              update.isValid else {
            // Clear stale data
            removeObject(forKey: pendingUpdateKey)
            return nil
        }
        return update
    }
    
    /// Clear the pending update
    func clearPendingUpdate() {
        removeObject(forKey: pendingUpdateKey)
    }
}

// MARK: - Shared Model Container
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
