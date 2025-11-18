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
    func goalProgress() -> (completed: Int, target: Int)? {
        guard let goal = intakeGoal else { return nil }
        return (dosesInCurrentPeriod(), goal.targetDoses)
    }
    
    /// Calculates the adherence streak (consecutive periods meeting the goal).
    func adherenceStreak() -> Int {
        guard let goal = intakeGoal else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var checkDate = now
        
        // Check backwards through time periods
        for _ in 0..<365 { // Max 1 year check
            let periodStart: Date
            let periodEnd: Date
            
            switch goal.period {
            case .perDay:
                periodStart = calendar.startOfDay(for: checkDate)
                periodEnd = calendar.date(byAdding: .day, value: 1, to: periodStart) ?? checkDate
            case .perWeek:
                guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: checkDate) else { 
                    return streak // Exit early if we can't get interval
                }
                periodStart = weekInterval.start
                periodEnd = weekInterval.end
            case .perMonth:
                guard let monthInterval = calendar.dateInterval(of: .month, for: checkDate) else { 
                    return streak // Exit early if we can't get interval
                }
                periodStart = monthInterval.start
                periodEnd = monthInterval.end
            }
            
            // Count doses in this period
            let dosesInPeriod = unwrappedLog.filter { log in
                !log.isRefill && log.timestamp >= periodStart && log.timestamp < periodEnd
            }.count
            
            if dosesInPeriod >= goal.targetDoses {
                streak += 1
                // Move to previous period
                checkDate = calendar.date(byAdding: .day, value: -1, to: periodStart) ?? Date.distantPast
            } else {
                break
            }
        }
        
        return streak
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
