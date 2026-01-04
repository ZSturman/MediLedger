//
//  MedicationActions.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/26/25.
//

import Foundation
import SwiftUI
import SwiftData


extension Med {
    
    /// Consumes a dose of medication and logs the intake.
    ///
    /// - Parameters:
    ///   - dose: The amount to consume. When `unit` is `.pill`, this represents the number of pills. When `unit` is `.mg`, this represents the milligrams to consume.
    ///   - unit: The unit of the dose. Defaults to `.pill`.
    ///   - context: Optional model context for saving changes.
    func takeMedication(dose: Double = 1, unit: DosageUnit = .pill, context: ModelContext? = nil) throws {
        let doseInMg: Double = (unit == .pill) ? dose * mgPerPill : dose
        totalMgRemaining -= doseInMg
        let logEntry = MedLog(mgIntake: -doseInMg, totalMgRemaining: totalMgRemaining)
        log?.append(logEntry)
        try context?.save()
    }
    
    /// Refills the medication by adding the full supply, updates fill dates, and logs the refill.
    /// **Prescription medications only.**
    ///
    /// - Parameter context: Optional model context for saving changes.
    func refillMedication(context: ModelContext? = nil) throws {
        guard medicationType == .prescription else {
            throw MedicationError.notApplicableForNonPrescription
        }
        
        let refillAmount = initialPillCount * mgPerPill
        totalMgRemaining += refillAmount
        
        let currentDate = Date()
        let nextFill = Calendar.current.date(
            byAdding: .day,
            value: Int(numberOfDaysSupply ?? 30),
            to: currentDate
        ) ?? currentDate
        
        lastFilledOn = currentDate
        nextFillDate = nextFill
        
        // Decrement refills remaining if tracked
        if let remaining = refillsRemaining, remaining > 0 {
            refillsRemaining = remaining - 1
        }
        
        let logEntry = MedLog(mgIntake: refillAmount, totalMgRemaining: totalMgRemaining)
        log?.append(logEntry)
        
        try context?.save()
    }
    
    /// Restocks a non-prescription medication (e.g., vitamins, supplements).
    /// Updates the total remaining but does not affect refill dates.
    ///
    /// - Parameters:
    ///   - quantity: The number of pills/servings to add.
    ///   - context: Optional model context for saving changes.
    func restockBottle(quantity: Double, context: ModelContext? = nil) throws {
        guard medicationType == .nonPrescription else {
            throw MedicationError.notApplicableForPrescription
        }
        
        let restockAmount = quantity * mgPerPill
        totalMgRemaining += restockAmount
        
        let logEntry = MedLog(mgIntake: restockAmount, totalMgRemaining: totalMgRemaining)
        log?.append(logEntry)
        
        try context?.save()
    }
    
    // MARK: - Goal Tracking Helpers
    
    /// Calculates how many doses have been taken in the current goal period.
    func dosesInCurrentPeriod() -> Int {
        guard let goal = intakeGoal else { return 0 }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfPeriod: Date
        
        switch goal.period {
        case .perDay:
            startOfPeriod = calendar.startOfDay(for: now)
        case .perWeek:
            startOfPeriod = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .perMonth:
            startOfPeriod = calendar.dateInterval(of: .month, for: now)?.start ?? now
        }
        
        // Count non-refill logs since start of period
        let periodLogs = unwrappedLog.filter { log in
            !log.isRefill && log.timestamp >= startOfPeriod
        }
        
        return periodLogs.count
    }
    
    /// Calculates goal progress as a tuple (completed, target).
    /// For "at least" goals, returns (doses, minimum).
    /// For "no more than" goals, returns (doses, maximum).
    /// For "both" goals, returns (doses, minimum) - use goalMaximum() for max.
    func goalProgress() -> (completed: Int, target: Int)? {
        guard let goal = intakeGoal else { return nil }
        let doses = dosesInCurrentPeriod()
        
        switch goal.constraintType {
        case .atLeast, .both:
            return (doses, Int(goal.targetDoses))
        case .noMoreThan:
            return (doses, Int(goal.maximumDoses ?? goal.targetDoses))
        }
    }
    
    /// Returns the maximum doses for the goal (for "both" or "no more than" constraints).
    func goalMaximum() -> Int? {
        guard let goal = intakeGoal else { return nil }
        
        switch goal.constraintType {
        case .noMoreThan, .both:
            return Int(goal.maximumDoses ?? goal.targetDoses)
        case .atLeast:
            return nil
        }
    }
    
    /// Checks if the current period meets the goal constraints.
    func meetsGoalForPeriod(doses: Int) -> Bool {
        guard let goal = intakeGoal else { return false }
        let doseCount = Double(doses)
        
        switch goal.constraintType {
        case .atLeast:
            return doseCount >= goal.targetDoses
        case .noMoreThan:
            return doseCount <= (goal.maximumDoses ?? goal.targetDoses)
        case .both:
            let meetsMin = doseCount >= goal.targetDoses
            let meetsMax = doseCount <= (goal.maximumDoses ?? Double.greatestFiniteMagnitude)
            return meetsMin && meetsMax
        }
    }
}

// MARK: - Error Types

enum MedicationError: LocalizedError {
    case notApplicableForNonPrescription
    case notApplicableForPrescription
    
    var errorDescription: String? {
        switch self {
        case .notApplicableForNonPrescription:
            return "This action is only available for prescription medications."
        case .notApplicableForPrescription:
            return "This action is only available for non-prescription medications."
        }
    }
}
