//
//  Intents.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
//

import AppIntents
import SwiftData
import WidgetKit

struct TakeHalf: AppIntent {
    static var title: LocalizedStringResource = "Take Half of Medication"
    
    // Parameter is now a MedEntity which lets the system provide a list of available medications.
    @Parameter(title: "Medication")
    var medication: MedEntity
    
    init(medication: MedEntity) {
        self.medication = medication
    }
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        //let context = ModelContext(modelContainer)
        let container = sharedModelContainer
        let context = ModelContext(container)
        
        // Capture medication.id in a local constant
        let medID = medication.id
        let fetchDescriptor = FetchDescriptor<Med>(predicate: #Predicate { med in
            med.id == medID
        })
        let meds = try context.fetch(fetchDescriptor)
        
        if let med = meds.first {
            try med.takeMedication(dose: 0.5, unit: .pill, context: context)
            try? context.save()
            
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
    
//    @Dependency(key: "ModelContainer")
//    private var modelContainer: ModelContainer
}

struct TakeMedication: AppIntent {
    static var title: LocalizedStringResource = "Take Medication"
    
    // Parameter is now a MedEntity which lets the system provide a list of available medications.
    @Parameter(title: "Medication")
    var medication: MedEntity
    
    init(medication: MedEntity) {
        self.medication = medication
    }
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        //let context = ModelContext(modelContainer)
        // Capture medication.id in a local constant
        let container = sharedModelContainer
        let context = ModelContext(container)
        
        let medID = medication.id
        let fetchDescriptor = FetchDescriptor<Med>(predicate: #Predicate { med in
            med.id == medID
        })
        let meds = try context.fetch(fetchDescriptor)
        
        if let med = meds.first {
            // Defaults to 1 pill (full dose)
            try med.takeMedication(context: context)
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
    }
    
//    @Dependency(key: "ModelContainer")
//    private var modelContainer: ModelContainer
}

struct GetRefill: AppIntent {
    
    static var title: LocalizedStringResource = "Refill Medication"
    
    // Parameter is now a MedEntity.
    @Parameter(title: "Medication")
    var medication: MedEntity
    
    func perform() async throws -> some IntentResult {
        //let context = ModelContext(modelContainer)
        let container = sharedModelContainer
        let context = ModelContext(container)
        
        // Capture medication.id in a local constant
        let medID = medication.id
        let fetchDescriptor = FetchDescriptor<Med>(predicate: #Predicate { med in
            med.id == medID
        })
        let meds = try context.fetch(fetchDescriptor)
        
        if let med = meds.first {
            try med.refillMedication(context: context)
            try? context.save()
        }
        
        return .result()
    }
    
//    @Dependency(key: "ModelContainer")
//    private var modelContainer: ModelContainer
}

