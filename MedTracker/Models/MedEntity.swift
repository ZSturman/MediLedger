//
//  MedEntity.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import AppIntents
import SwiftData

struct MedicationEntityQuery: EntityQuery {
//    @Dependency(key: "ModelContainer")
//    private var modelContainer: ModelContainer
    
    let container = sharedModelContainer
  

    func entities(for identifiers: [MedEntity.ID]) async throws -> [MedEntity] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<Med>()
        let meds = try context.fetch(fetchDescriptor)
        
        // Map each Med to a MedEntity.
        let entities = meds.map { med in
            let goalProgress = med.goalProgress()
            return MedEntity(
                id: med.id,
                name: med.name,
                medicationType: med.medicationType,
                pillForm: med.pillForm,
                nextDoseTime: med.calculatedNextDoseTime,
                lastFilledOn: med.lastFilledOn,
                nextFillDate: med.nextFillDate,
                totalMgRemaining: med.totalMgRemaining,
                numberOfDaysSupply: med.numberOfDaysSupply,
                initialPillCount: med.initialPillCount,
                mgPerPill: med.mgPerPill,
                pillsPerDayLeft: med.pillsPerDayLeft,
                daysUntilRefill: med.daysUntilRefill,
                pillsRemaining: med.pillsRemaining,
                refillsRemaining: med.refillsRemaining,
                goalProgressCompleted: goalProgress?.completed,
                goalProgressTarget: goalProgress?.target
            )
        }
        
        // If identifiers are provided, filter by them; otherwise, return all.
        if identifiers.isEmpty {
            return entities
        } else {
            return entities.filter { identifiers.contains($0.id) }
        }
    }
}

extension MedicationEntityQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [MedEntity] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<Med>()
        let meds = try context.fetch(fetchDescriptor)
        return meds.map { med in
            let goalProgress = med.goalProgress()
            return MedEntity(
                id: med.id,
                name: med.name,
                medicationType: med.medicationType,
                pillForm: med.pillForm,
                nextDoseTime: med.calculatedNextDoseTime,
                lastFilledOn: med.lastFilledOn,
                nextFillDate: med.nextFillDate,
                totalMgRemaining: med.totalMgRemaining,
                numberOfDaysSupply: med.numberOfDaysSupply,
                initialPillCount: med.initialPillCount,
                mgPerPill: med.mgPerPill,
                pillsPerDayLeft: med.pillsPerDayLeft,
                daysUntilRefill: med.daysUntilRefill,
                pillsRemaining: med.pillsRemaining,
                refillsRemaining: med.refillsRemaining,
                goalProgressCompleted: goalProgress?.completed,
                goalProgressTarget: goalProgress?.target
            )
        }
    }
    
    func suggestedEntities() async throws -> [MedEntity] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<Med>()
        let meds = try context.fetch(fetchDescriptor)
        return meds.map { med in
            let goalProgress = med.goalProgress()
            return MedEntity(
                id: med.id,
                name: med.name,
                medicationType: med.medicationType,
                pillForm: med.pillForm,
                nextDoseTime: med.calculatedNextDoseTime,
                lastFilledOn: med.lastFilledOn,
                nextFillDate: med.nextFillDate,
                totalMgRemaining: med.totalMgRemaining,
                numberOfDaysSupply: med.numberOfDaysSupply,
                initialPillCount: med.initialPillCount,
                mgPerPill: med.mgPerPill,
                pillsPerDayLeft: med.pillsPerDayLeft,
                daysUntilRefill: med.daysUntilRefill,
                pillsRemaining: med.pillsRemaining,
                refillsRemaining: med.refillsRemaining,
                goalProgressCompleted: goalProgress?.completed,
                goalProgressTarget: goalProgress?.target
            )
        }
    }
    
    func defaultResult() async -> MedEntity? {
        try? await suggestedEntities().first
    }
}



struct MedEntity: AppEntity {
    var id: String
    var name: String
    var medicationType: MedicationType
    var pillForm: MedicationForm
    var nextDoseTime: Date?
    var lastFilledOn: Date?
    var nextFillDate: Date?
    var totalMgRemaining: Double
    var numberOfDaysSupply: Double?
    var initialPillCount: Double
    var mgPerPill: Double
    var pillsPerDayLeft: Double
    var daysUntilRefill: Int
    var pillsRemaining: Double
    var refillsRemaining: Int?
    
    // Goal-related properties
    var goalProgressCompleted: Int?
    var goalProgressTarget: Int?
    
    static var defaultQuery = MedicationEntityQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("Medication", table: "AppIntents"))
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }
}
