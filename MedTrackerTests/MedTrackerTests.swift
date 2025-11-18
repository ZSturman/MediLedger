//
//  MedTrackerTests.swift
//  MedTrackerTests
//
//  Created by Zachary Sturman on 3/24/25.
//

import Testing
import SwiftData
import Foundation
@testable import MedTracker

struct MedTrackerTests {
    
    // MARK: - Test Helpers
    
    /// Creates an in-memory ModelContainer for testing
    @MainActor
    func createTestContainer() throws -> ModelContainer {
        let schema = Schema([Med.self, MedLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
    
    /// Creates a test prescription medication
    @MainActor
    func createTestPrescriptionMed(context: ModelContext) -> Med {
        let med = Med(
            name: "Test Prescription",
            desc: "A test prescription medication",
            medicationType: .prescription,
            pillForm: "Tablet",
            lastFilledOn: Date(),
            nextFillDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            totalMgRemaining: 600.0, // 30 pills * 20mg
            numberOfDaysSupply: 30,
            initialPillCount: 30,
            mgPerPill: 20.0,
            dailyDosage: 1,
            dailyDosageUnit: .pill,
            prescriberName: "Dr. Smith",
            pharmacyName: "Test Pharmacy",
            rxNumber: "RX12345",
            refillsRemaining: 3
        )
        context.insert(med)
        return med
    }
    
    /// Creates a test non-prescription medication
    @MainActor
    func createTestNonPrescriptionMed(context: ModelContext) -> Med {
        let med = Med(
            name: "Test Vitamin D",
            desc: "A test vitamin supplement",
            medicationType: .nonPrescription,
            pillForm: "Softgel",
            totalMgRemaining: 2000.0, // 100 pills * 20IU
            initialPillCount: 100,
            mgPerPill: 20.0,
            dailyDosage: 1,
            dailyDosageUnit: .pill,
            brandName: "NatureMade",
            supplementType: "Vitamin D3",
            servingSize: 1,
            servingsPerContainer: 100,
            purchaseLocation: "Costco"
        )
        context.insert(med)
        return med
    }
    
    /// Creates a medication with an intake goal
    @MainActor
    func createMedWithGoal(context: ModelContext, period: GoalPeriod = .perDay, target: Int = 1) -> Med {
        let goal = IntakeGoal(
            targetDoses: target,
            period: period,
            specificDays: nil,
            timesOfDay: nil,
            startDate: Date()
        )
        
        let med = Med(
            name: "Test Med with Goal",
            medicationType: .prescription,
            lastFilledOn: Date(),
            nextFillDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            totalMgRemaining: 600.0,
            numberOfDaysSupply: 30,
            initialPillCount: 30,
            mgPerPill: 20.0,
            intakeGoal: goal
        )
        context.insert(med)
        return med
    }
    
    // MARK: - Medication Model Tests
    
    @Test("Create prescription medication")
    @MainActor
    func testCreatePrescriptionMedication() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        #expect(med.name == "Test Prescription")
        #expect(med.medicationType == .prescription)
        #expect(med.mgPerPill == 20.0)
        #expect(med.totalMgRemaining == 600.0)
        #expect(med.pillsRemaining == 30.0)
        #expect(med.refillsRemaining == 3)
    }
    
    @Test("Create non-prescription medication")
    @MainActor
    func testCreateNonPrescriptionMedication() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestNonPrescriptionMed(context: context)
        
        #expect(med.name == "Test Vitamin D")
        #expect(med.medicationType == .nonPrescription)
        #expect(med.brandName == "NatureMade")
        #expect(med.supplementType == "Vitamin D3")
        #expect(med.totalMgRemaining == 2000.0)
        #expect(med.pillsRemaining == 100.0)
    }
    
    @Test("Take full dose of medication")
    @MainActor
    func testTakeFullDose() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let initialRemaining = med.totalMgRemaining
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        #expect(med.totalMgRemaining == initialRemaining - 20.0)
        #expect(med.unwrappedLog.count == 1)
        #expect(med.unwrappedLog.first?.mgIntake == -20.0)
    }
    
    @Test("Take half dose of medication")
    @MainActor
    func testTakeHalfDose() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let initialRemaining = med.totalMgRemaining
        
        try med.takeMedication(dose: 0.5, unit: .pill, context: context)
        
        #expect(med.totalMgRemaining == initialRemaining - 10.0)
        #expect(med.unwrappedLog.count == 1)
        #expect(med.unwrappedLog.first?.mgIntake == -10.0)
    }
    
    @Test("Take medication by mg amount")
    @MainActor
    func testTakeMedicationByMg() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let initialRemaining = med.totalMgRemaining
        
        try med.takeMedication(dose: 15.0, unit: .mg, context: context)
        
        #expect(med.totalMgRemaining == initialRemaining - 15.0)
        #expect(med.unwrappedLog.count == 1)
        #expect(med.unwrappedLog.first?.mgIntake == -15.0)
    }
    
    @Test("Multiple doses in one day")
    @MainActor
    func testMultipleDosesInDay() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let initialRemaining = med.totalMgRemaining
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 0.5, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        #expect(med.totalMgRemaining == initialRemaining - 50.0) // 20 + 10 + 20
        #expect(med.unwrappedLog.count == 3)
    }
    
    @Test("Refill prescription medication")
    @MainActor
    func testRefillPrescription() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        // Take some medication first
        try med.takeMedication(dose: 10, unit: .pill, context: context)
        let remainingAfterDoses = med.totalMgRemaining
        
        // Refill
        let initialRefills = med.refillsRemaining
        try med.refillMedication(context: context)
        
        #expect(med.totalMgRemaining == remainingAfterDoses + 600.0)
        #expect(med.refillsRemaining == (initialRefills! - 1))
        #expect(med.unwrappedLog.contains(where: { $0.isRefill }))
    }
    
    @Test("Refill updates dates correctly")
    @MainActor
    func testRefillUpdatesDates() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let oldFillDate = med.lastFilledOn
        
        // Wait a moment to ensure date changes
        Thread.sleep(forTimeInterval: 0.1)
        
        try med.refillMedication(context: context)
        
        #expect(med.lastFilledOn != oldFillDate)
        #expect(med.lastFilledOn! > oldFillDate!)
        #expect(med.nextFillDate != nil)
    }
    
    @Test("Non-prescription cannot refill")
    @MainActor
    func testNonPrescriptionCannotRefill() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestNonPrescriptionMed(context: context)
        
        #expect(throws: MedicationError.self) {
            try med.refillMedication(context: context)
        }
    }
    
    @Test("Restock non-prescription medication")
    @MainActor
    func testRestockNonPrescription() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestNonPrescriptionMed(context: context)
        
        // Take some first
        try med.takeMedication(dose: 50, unit: .pill, context: context)
        let remainingAfterDoses = med.totalMgRemaining
        
        // Restock
        try med.restockBottle(quantity: 100, context: context)
        
        #expect(med.totalMgRemaining == remainingAfterDoses + 2000.0)
        #expect(med.unwrappedLog.contains(where: { $0.isRefill }))
    }
    
    @Test("Prescription cannot restock")
    @MainActor
    func testPrescriptionCannotRestock() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        #expect(throws: MedicationError.self) {
            try med.restockBottle(quantity: 100, context: context)
        }
    }
    
    @Test("Pills per day left calculation")
    @MainActor
    func testPillsPerDayLeft() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        // Should have 30 pills over 30 days = 1 per day
        let pillsPerDay = med.pillsPerDayLeft
        #expect(pillsPerDay >= 0.9 && pillsPerDay <= 1.1) // Allow small rounding variance
    }
    
    @Test("Days until refill calculation")
    @MainActor
    func testDaysUntilRefill() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        let days = med.daysUntilRefill
        #expect(days >= 29 && days <= 30) // Should be around 30 days
    }
    
    @Test("Pills remaining calculation")
    @MainActor
    func testPillsRemaining() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        #expect(med.pillsRemaining == 30.0)
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        #expect(med.pillsRemaining == 29.0)
    }
    
    // MARK: - Goal Tracking Tests
    
    @Test("Create medication with daily goal")
    @MainActor
    func testCreateMedicationWithDailyGoal() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 2)
        
        #expect(med.intakeGoal != nil)
        #expect(med.intakeGoal?.targetDoses == 2)
        #expect(med.intakeGoal?.period == .perDay)
    }
    
    @Test("Goal progress tracking - no doses")
    @MainActor
    func testGoalProgressNoDoses() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 2)
        
        let progress = med.goalProgress()
        #expect(progress?.completed == 0)
        #expect(progress?.target == 2)
    }
    
    @Test("Goal progress tracking - with doses")
    @MainActor
    func testGoalProgressWithDoses() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 2)
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        let progress = med.goalProgress()
        #expect(progress?.completed == 1)
        #expect(progress?.target == 2)
    }
    
    @Test("Goal progress - meeting target")
    @MainActor
    func testGoalProgressMeetingTarget() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 2)
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        let progress = med.goalProgress()
        #expect(progress?.completed == 2)
        #expect(progress?.target == 2)
    }
    
    @Test("Goal progress - exceeding target")
    @MainActor
    func testGoalProgressExceedingTarget() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 2)
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        let progress = med.goalProgress()
        #expect(progress?.completed == 3)
        #expect(progress?.target == 2)
    }
    
    @Test("Adherence streak - no doses")
    @MainActor
    func testAdherenceStreakNoDoses() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 1)
        
        let streak = med.adherenceStreak()
        #expect(streak == 0)
    }
    
    @Test("Adherence streak - meeting goal today")
    @MainActor
    func testAdherenceStreakMeetingToday() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 1)
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        let streak = med.adherenceStreak()
        #expect(streak == 1)
    }
    
    @Test("Weekly goal tracking")
    @MainActor
    func testWeeklyGoalTracking() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perWeek, target: 7)
        
        // Take 3 doses this week
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        
        let progress = med.goalProgress()
        #expect(progress?.completed == 3)
        #expect(progress?.target == 7)
    }
    
    @Test("Goal with specific weekdays")
    @MainActor
    func testGoalWithSpecificWeekdays() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let specificDays: Set<Weekday> = [.monday, .wednesday, .friday]
        let goal = IntakeGoal(
            targetDoses: 3,
            period: .perWeek,
            specificDays: specificDays,
            timesOfDay: nil,
            startDate: Date()
        )
        
        let med = Med(
            name: "Test Med",
            medicationType: .prescription,
            lastFilledOn: Date(),
            nextFillDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            totalMgRemaining: 600.0,
            numberOfDaysSupply: 30,
            initialPillCount: 30,
            mgPerPill: 20.0,
            intakeGoal: goal
        )
        context.insert(med)
        
        #expect(med.intakeGoal?.specificDays == specificDays)
        #expect(med.intakeGoal?.specificDays?.count == 3)
    }
    
    // MARK: - Data Persistence Tests
    
    @Test("Save and fetch medication")
    @MainActor
    func testSaveAndFetchMedication() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        _ = createTestPrescriptionMed(context: context)
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<Med>()
        let fetchedMeds = try context.fetch(fetchDescriptor)
        
        #expect(fetchedMeds.count == 1)
        #expect(fetchedMeds.first?.name == "Test Prescription")
    }
    
    @Test("Medication logs are persisted")
    @MainActor
    func testMedicationLogsPersisted() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<Med>()
        let fetchedMeds = try context.fetch(fetchDescriptor)
        
        #expect(fetchedMeds.first?.unwrappedLog.count == 1)
    }
    
    @Test("Multiple medications can be stored")
    @MainActor
    func testMultipleMedications() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        _ = createTestPrescriptionMed(context: context)
        _ = createTestNonPrescriptionMed(context: context)
        _ = createMedWithGoal(context: context)
        
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<Med>()
        let fetchedMeds = try context.fetch(fetchDescriptor)
        
        #expect(fetchedMeds.count == 3)
    }
    
    @Test("Delete medication")
    @MainActor
    func testDeleteMedication() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        try context.save()
        
        context.delete(med)
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<Med>()
        let fetchedMeds = try context.fetch(fetchDescriptor)
        
        #expect(fetchedMeds.count == 0)
    }
    
    @Test("Cascade delete removes logs")
    @MainActor
    func testCascadeDeleteLogs() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try context.save()
        
        let logCountBefore = try context.fetch(FetchDescriptor<MedLog>()).count
        #expect(logCountBefore == 2)
        
        context.delete(med)
        try context.save()
        
        let logCountAfter = try context.fetch(FetchDescriptor<MedLog>()).count
        #expect(logCountAfter == 0)
    }
    
    // MARK: - Widget Data Tests
    
    @Test("MedEntity creation from Med")
    @MainActor
    func testMedEntityCreation() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let goalProgress = med.goalProgress()
        
        let entity = MedEntity(
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
            adherenceStreak: nil
        )
        
        #expect(entity.name == "Test Prescription")
        #expect(entity.medicationType == .prescription)
        #expect(entity.pillsRemaining == 30.0)
    }
    
    @MainActor @Test("MedEntity always has valid data")
    func testMedEntityAlwaysHasData() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        try context.save()
        
        let goalProgress = med.goalProgress()
        let entity = MedEntity(
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
        
        // Ensure all required fields have values
        #expect(!entity.id.isEmpty)
        #expect(!entity.name.isEmpty)
        #expect(entity.totalMgRemaining >= 0)
        #expect(entity.pillsPerDayLeft >= 0)
        #expect(entity.daysUntilRefill >= 0)
        #expect(entity.pillsRemaining >= 0)
    }
    
    @Test("Widget data updates after medication intake")
    @MainActor
    func testWidgetDataUpdatesAfterIntake() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let initialRemaining = med.pillsRemaining
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try context.save()
        
        #expect(med.pillsRemaining == initialRemaining - 1)
        #expect(med.totalMgRemaining < 600.0)
    }
    
    @Test("Widget data for medication with goal")
    @MainActor
    func testWidgetDataWithGoal() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createMedWithGoal(context: context, period: .perDay, target: 2)
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        try context.save()
        
        let goalProgress = med.goalProgress()
        let entity = MedEntity(
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
            refillsRemaining: nil,
            goalProgressCompleted: goalProgress?.completed,
            goalProgressTarget: goalProgress?.target,
            adherenceStreak: med.adherenceStreak()
        )
        
        #expect(entity.goalProgressCompleted == 1)
        #expect(entity.goalProgressTarget == 2)
        #expect(entity.adherenceStreak != nil)
    }
    
    // MARK: - Edge Cases
    
    @Test("Zero remaining medication")
    @MainActor
    func testZeroRemainingMedication() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = Med(
            name: "Empty Med",
            medicationType: .prescription,
            lastFilledOn: Date(),
            nextFillDate: Date(),
            totalMgRemaining: 0.0,
            numberOfDaysSupply: 30,
            initialPillCount: 30,
            mgPerPill: 20.0
        )
        context.insert(med)
        
        #expect(med.pillsRemaining == 0.0)
        #expect(med.totalMgRemaining == 0.0)
    }
    
    @Test("Very large medication supply")
    @MainActor
    func testLargeMedicationSupply() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = Med(
            name: "Large Supply",
            medicationType: .prescription,
            lastFilledOn: Date(),
            nextFillDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()),
            totalMgRemaining: 180000.0, // 9000 pills * 20mg
            numberOfDaysSupply: 90,
            initialPillCount: 9000,
            mgPerPill: 20.0
        )
        context.insert(med)
        
        #expect(med.pillsRemaining == 9000.0)
        try med.takeMedication(dose: 100, unit: .pill, context: context)
        #expect(med.pillsRemaining == 8900.0)
    }
    
    @Test("Fractional pill dosage")
    @MainActor
    func testFractionalPillDosage() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        
        try med.takeMedication(dose: 0.25, unit: .pill, context: context)
        try med.takeMedication(dose: 0.75, unit: .pill, context: context)
        
        #expect(med.totalMgRemaining == 600.0 - 20.0) // One full pill taken
    }
    
    @Test("MedLog tracks remaining correctly over multiple actions")
    @MainActor
    func testMedLogTracksRemainingCorrectly() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let med = createTestPrescriptionMed(context: context)
        let initialLogCount = med.unwrappedLog.count
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        // Get the first new log entry (last item in the array after first take)
        let firstLog = med.unwrappedLog[initialLogCount]
        
        try med.takeMedication(dose: 1, unit: .pill, context: context)
        // Get the second new log entry (last item in the array after second take)
        let secondLog = med.unwrappedLog[initialLogCount + 1]
        
        // First take: 600 - 20 = 580mg remaining
        #expect(firstLog.totalMgRemaining == 580.0)
        // Second take: 580 - 20 = 560mg remaining  
        #expect(secondLog.totalMgRemaining == 560.0)
        #expect(med.totalMgRemaining == 560.0)
    }

}
