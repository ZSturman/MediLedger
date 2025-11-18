//
//  AppIntent.swift
//  MedTrackerWidget
//
//  Created by Zachary Sturman on 3/28/25.
//

import WidgetKit
import AppIntents
import SwiftData


enum WidgetDisplay: String, AppEnum {
    // Universal (both prescription and non-prescription)
    case leftPerDay = "Left per day"
    case lastTookAt = "Last took at"
    case totalLeft = "Total left"
    case totalToday = "Total today"
    case averageDailyIntake = "Average daily intake"
    case pillsRemaining = "Pills remaining"
    case weeklyIntake = "Weekly intake"
    
    // Goal-based (both types, requires goal to be set)
    case goalProgress = "Goal progress"
    case adherenceStreak = "Adherence streak"
    
    // Prescription-specific
    case dailyAverageSinceRefill = "Average since refill"
    case daysUntilRefill = "Days until refill"
    case nextScheduledDose = "Next scheduled dose"
    case dosesLeftToday = "Doses left today"
    case refillsRemaining = "Refills remaining"
    
    // Non-prescription specific
    case bottleQuantityRemaining = "Bottle quantity"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Display Option"
    }

    static var caseDisplayRepresentations: [WidgetDisplay: DisplayRepresentation] {
        [
            // Universal
            .leftPerDay: "Pills Per Day Left",
            .lastTookAt: "Last Intake Time",
            .totalLeft: "Total Pills Left",
            .totalToday: "Today's Total Intake",
            .averageDailyIntake: "7-Day Average",
            .pillsRemaining: "Pills Remaining",
            .weeklyIntake: "This Week's Intake",
            
            // Goal-based
            .goalProgress: "Goal Progress",
            .adherenceStreak: "Current Streak",
            
            // Prescription
            .dailyAverageSinceRefill: "Average Since Refill",
            .daysUntilRefill: "Days Until Refill",
            .nextScheduledDose: "Next Dose Time",
            .dosesLeftToday: "Doses Left Today",
            .refillsRemaining: "Refills Remaining",
            
            // Non-prescription
            .bottleQuantityRemaining: "Bottle Quantity",
        ]
    }
}


struct SelectMedicationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Chosen medication for quick actions." }

    @Parameter(title: "Chosen Medication")
    var chosenMedication: MedEntity?
    
    @Parameter(title: "Primary")
    var primaryWidgetDisplay: WidgetDisplay?
    
    @Parameter(title: "Secondary")
    var secondaryWidgetDisplay: WidgetDisplay?
    

    init(chosenMedication: MedEntity?, primaryWidgetDisplay: WidgetDisplay?, secondaryWidgetDisplay: WidgetDisplay?) {
        self.chosenMedication = chosenMedication
        self.primaryWidgetDisplay = primaryWidgetDisplay
        self.secondaryWidgetDisplay = secondaryWidgetDisplay
    }

    init() { }
}
