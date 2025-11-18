//
//  MedTrackerWidget.swift
//  MedTrackerWidget
//
//  Created by Zachary Sturman on 3/28/25.
//

import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

// MARK: - Timeline Entry Updated with Last Log
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: SelectMedicationIntent
    let logs: [MedLog]?
}

// MARK: - Provider Updates
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: SelectMedicationIntent(), logs: nil)
    }

    func snapshot(for configuration: SelectMedicationIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, logs: nil)
    }
    
    func timeline(for configuration: SelectMedicationIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let medication: MedEntity
        
        if let configuredMed = configuration.chosenMedication {
            medication = configuredMed
        } else {
            do {
                let container = try ModelContainer(for: Med.self)
                let context = ModelContext(container)
                let fetchDescriptor = FetchDescriptor<Med>(predicate: #Predicate { _ in true })
                if let med = try context.fetch(fetchDescriptor).first {
                    let goalProgress = med.goalProgress()
                    medication = MedEntity(
                        id: med.id,
                        name: med.name,
                        medicationType: med.medicationType,
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
                        goalProgressTarget: goalProgress?.target,
                        adherenceStreak: med.intakeGoal != nil ? med.adherenceStreak() : nil
                    )
                } else {
                    medication = MedEntity(
                        id: UUID().uuidString,
                        name: "Default Medication",
                        medicationType: .prescription,
                        lastFilledOn: Date(),
                        nextFillDate: Date(),
                        totalMgRemaining: 0.0,
                        numberOfDaysSupply: 0.0,
                        initialPillCount: 0.0,
                        mgPerPill: 0.0,
                        pillsPerDayLeft: 0.0,
                        daysUntilRefill: 0,
                        pillsRemaining: 0.0,
                        refillsRemaining: nil,
                        goalProgressCompleted: nil,
                        goalProgressTarget: nil,
                        adherenceStreak: nil
                    )
                }
            } catch {
                medication = MedEntity(
                    id: UUID().uuidString,
                    name: "Default Medication",
                    medicationType: .prescription,
                    lastFilledOn: Date(),
                    nextFillDate: Date(),
                    totalMgRemaining: 0.0,
                    numberOfDaysSupply: 0.0,
                    initialPillCount: 0.0,
                    mgPerPill: 0.0,
                    pillsPerDayLeft: 0.0,
                    daysUntilRefill: 0,
                    pillsRemaining: 0.0,
                    refillsRemaining: nil,
                    goalProgressCompleted: nil,
                    goalProgressTarget: nil,
                    adherenceStreak: nil
                )
            }
        }

        // Use the medication's id (which is non-optional) to fetch its logs.
        let chosenMedID = medication.id
        var fetchedLog: [MedLog]? = nil

        do {
            let container = try ModelContainer(for: Med.self)
            let context = ModelContext(container)
            let fetchDescriptor = FetchDescriptor<Med>(predicate: #Predicate { med in
                med.id == chosenMedID
            })
            if let meds = try? context.fetch(fetchDescriptor),
               let med = meds.first {
                fetchedLog = med.unwrappedLog
            }
        } catch {
            print("Error initializing ModelContainer: \(error)")
        }

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, configuration: configuration, logs: fetchedLog)
        return Timeline(entries: [entry], policy: .atEnd)
    }
}

// MARK: - Updated Widget View
struct MedTrackerWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let medEntity = entry.configuration.chosenMedication {
                MedicationWidgetView(med: medEntity, logs: entry.logs ?? [], primary: entry.configuration.primaryWidgetDisplay ?? .leftPerDay, secondary: entry.configuration.secondaryWidgetDisplay ?? .lastTookAt)
            } else {
                NoMedicationSelectedWidgetView()
            }
        }
    }
}

// MARK: - Widget Definition
struct MedTrackerWidget: Widget {
    let kind: String = "MedTrackerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectMedicationIntent.self, provider: Provider()) { entry in
            MedTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MedTracker")
        .description("Quick actions for your chosen medication.")
        .supportedFamilies([.systemSmall])
    }
}

//#Preview(as: .systemSmall) {
//    MedTrackerWidget()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .init(chosenMedication: MedEntity(id: "default-id", name: "Default Medication")), logs: nil)
//}
