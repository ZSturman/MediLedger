//
//  MedicationWidgetView.swift
//  MedTrackerWidgetExtension
//
//  Created by Zachary Sturman on 3/28/25.
//

import Foundation
import WidgetKit
import SwiftUI

// MARK: - Helper Functions

fileprivate func formatNumber(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)))
}

// MARK: - Main Widget View

struct MedicationWidgetView: View {
    var med: MedEntity
    var logs: [MedLog]
    var primary: WidgetDisplay
    var secondary: WidgetDisplay
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(med.name)
                .font(.subheadline)
                .lineLimit(1)
                .id(med.name)
                .transition(.opacity)
            
            // Secondary view (compact, single line)
            renderWidgetDisplay(secondary, isSecondary: true)
                .id("\(secondary.rawValue)-\(getSecondaryValueID())")
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            Divider()
            Spacer()
            
            HStack {
                Spacer()
                // Primary view (2-3 lines with prominent data)
                renderWidgetDisplay(primary, isSecondary: false)
                    .id("\(primary.rawValue)-\(getPrimaryValueID())")
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                Spacer()
            }
            
            Spacer()
            
            // Action buttons with visual feedback
            HStack(spacing: 12) {
                Spacer()
                Button(intent: TakeHalf(medication: med)) {
                    Image(systemName: "capsule.righthalf.filled")
                        .font(.system(size: 16))
                }
                .labelStyle(.iconOnly)
                .widgetAccentable()
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                )
             
                Spacer()
                Button(intent: TakeMedication(medication: med)) {
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 16))
                }
                .labelStyle(.iconOnly)
                .widgetAccentable()
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                )
          
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.easeInOut(duration: 0.3), value: med.totalMgRemaining)
        .animation(.easeInOut(duration: 0.3), value: logs.count)
    }
    
    // Helper to generate unique IDs for animation purposes
    private func getPrimaryValueID() -> String {
        switch primary {
        case .leftPerDay:
            return "\(med.pillsPerDayLeft)"
        case .totalLeft:
            return "\(med.totalMgRemaining)"
        case .totalToday:
            return "\(logs.filter { !$0.isRefill && Calendar.current.isDateInToday($0.timestamp) }.reduce(0) { $0 + abs($1.mgIntake) })"
        case .pillsRemaining:
            return "\(med.pillsRemaining)"
        case .lastTookAt:
            return "\(logs.last(where: { !$0.isRefill })?.timestamp.timeIntervalSince1970 ?? 0)"
        default:
            return "\(med.totalMgRemaining)-\(logs.count)"
        }
    }
    
    private func getSecondaryValueID() -> String {
        switch secondary {
        case .leftPerDay:
            return "\(med.pillsPerDayLeft)"
        case .totalLeft:
            return "\(med.totalMgRemaining)"
        case .totalToday:
            return "\(logs.filter { !$0.isRefill && Calendar.current.isDateInToday($0.timestamp) }.reduce(0) { $0 + abs($1.mgIntake) })"
        case .pillsRemaining:
            return "\(med.pillsRemaining)"
        case .lastTookAt:
            return "\(logs.last(where: { !$0.isRefill })?.timestamp.timeIntervalSince1970 ?? 0)"
        default:
            return "\(med.totalMgRemaining)-\(logs.count)"
        }
    }
    
    @ViewBuilder
    private func renderWidgetDisplay(_ display: WidgetDisplay, isSecondary: Bool) -> some View {
        switch display {
        // Universal
        case .leftPerDay:
            LeftPerDay(med: med, isSecondary: isSecondary)
        case .lastTookAt:
            LastTookAt(logs: logs, isSecondary: isSecondary)
        case .totalLeft:
            TotalLeft(med: med, isSecondary: isSecondary)
        case .totalToday:
            TotalToday(logs: logs, isSecondary: isSecondary)
        case .averageDailyIntake:
            AverageDailyIntake(logs: logs, isSecondary: isSecondary)
        case .pillsRemaining:
            PillsRemainingView(med: med, isSecondary: isSecondary)
        case .weeklyIntake:
            WeeklyIntake(logs: logs, isSecondary: isSecondary)
            
        // Goal-based
        case .goalProgress:
            GoalProgressView(med: med, isSecondary: isSecondary)
        case .adherenceStreak:
            AdherenceStreakView(med: med, isSecondary: isSecondary)
            
        // Prescription-specific
        case .dailyAverageSinceRefill:
            DailyAverageSinceRefill(med: med, logs: logs, isSecondary: isSecondary)
        case .daysUntilRefill:
            DaysUntilRefill(med: med, isSecondary: isSecondary)
        case .nextScheduledDose:
            NextScheduledDose(med: med, isSecondary: isSecondary)
        case .dosesLeftToday:
            DosesLeftToday(med: med, logs: logs, isSecondary: isSecondary)
        case .refillsRemaining:
            RefillsRemaining(med: med, isSecondary: isSecondary)
            
        // Non-prescription specific
        case .bottleQuantityRemaining:
            BottleQuantityRemaining(med: med, isSecondary: isSecondary)
        }
    }
}

// MARK: - Universal Widget Displays

struct LastTookAt: View {
    var logs: [MedLog]
    var isSecondary: Bool = false
    
    private var lastLog: MedLog? {
        logs.last(where: { !$0.isRefill })
    }
    
    private var lastTookLogPrimary: (amount: String, time: String) {
        guard let log = lastLog else { return ("--", "--") }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let amount = "\(formatNumber(abs(log.mgIntake)))mg"
        let time = formatter.string(from: log.timestamp)
        return (amount, time)
    }
    
    private var lastLogTextSecondary: String {
        guard let log = lastLog else { return "Not taken yet" }
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .short
        let timeAgo = relativeFormatter.localizedString(for: log.timestamp, relativeTo: Date())
        let amount = "\(formatNumber(abs(log.mgIntake)))mg"
        return "\(amount) \(timeAgo)"
    }
    
    var body: some View {
        if isSecondary {
            Text(lastLogTextSecondary)
                .font(.caption2)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
        } else {
            VStack {
                Text("Last Took")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(lastTookLogPrimary.amount)
                    .font(.title2)
                    .bold()
                    .contentTransition(.numericText())
                Text(lastTookLogPrimary.time)
                    .font(.caption)
            }
        }
    }
}

struct LeftPerDay: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var valueText: String {
        guard med.medicationType == .prescription, med.daysUntilRefill > 0 else {
            return "--"
        }
        return formatNumber(med.pillsPerDayLeft)
    }
    
    var body: some View {
        if isSecondary {
            Text(med.medicationType == .prescription ? "Left/day: \(valueText)" : "N/A for non-Rx")
                .font(.caption2)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
        } else {
            VStack {
                Text("Pills Per Day Left")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if med.medicationType == .prescription && med.daysUntilRefill > 0 {
                    Text(valueText)
                        .font(.title)
                        .bold()
                        .contentTransition(.numericText())
                } else {
                    Text("N/A")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct TotalLeft: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var pillsLeft: Double {
        guard med.mgPerPill > 0 else { return 0 }
        return med.totalMgRemaining / med.mgPerPill
    }
    
    var valueText: String {
        formatNumber(pillsLeft)
    }
    
    var body: some View {
        if isSecondary {
            Text("Total: \(valueText) pills")
                .font(.caption2)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
        } else {
            VStack {
                Text("Total Pills Left")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title)
                    .bold()
                    .contentTransition(.numericText())
            }
        }
    }
}

struct TotalToday: View {
    var logs: [MedLog]
    var isSecondary: Bool = false
    
    var totalToday: Double {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        return logs.filter { log in
            !log.isRefill && log.timestamp >= startOfDay && log.timestamp <= now
        }
        .reduce(0) { $0 + abs($1.mgIntake) }
    }
    
    var valueText: String {
        "\(formatNumber(totalToday))mg"
    }
    
    var body: some View {
        if isSecondary {
            Text("Today: \(valueText)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
        } else {
            VStack {
                Text("Today's Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title2)
                    .bold()
                    .contentTransition(.numericText())
            }
        }
    }
}

struct PillsRemainingView: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var valueText: String {
        formatNumber(med.pillsRemaining)
    }
    
    var body: some View {
        if isSecondary {
            Text("Remaining: \(valueText)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
        } else {
            VStack {
                Text("Pills Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title)
                    .bold()
                    .contentTransition(.numericText())
            }
        }
    }
}

struct AverageDailyIntake: View {
    var logs: [MedLog]
    var isSecondary: Bool = false
    
    var averageIntake: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: now) else { return 0 }
        let filteredLogs = logs.filter { log in
            !log.isRefill && log.timestamp >= startDate && log.timestamp <= now
        }
        let total = filteredLogs.reduce(0) { $0 + abs($1.mgIntake) }
        return total / 7
    }
    
    var valueText: String {
        "\(formatNumber(averageIntake))mg"
    }
    
    var body: some View {
        if isSecondary {
            Text("7-day avg: \(valueText)")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            VStack {
                Text("7-Day Average")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title2)
                    .bold()
                Text("per day")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WeeklyIntake: View {
    var logs: [MedLog]
    var isSecondary: Bool = false
    
    var weeklyTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return logs.filter { log in
            !log.isRefill && log.timestamp >= weekStart && log.timestamp <= now
        }
        .reduce(0) { $0 + abs($1.mgIntake) }
    }
    
    var valueText: String {
        "\(formatNumber(weeklyTotal))mg"
    }
    
    var body: some View {
        if isSecondary {
            Text("This week: \(valueText)")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            VStack {
                Text("This Week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title2)
                    .bold()
            }
        }
    }
}

// MARK: - Goal-Based Widget Displays

struct GoalProgressView: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var progressText: String {
        guard let completed = med.goalProgressCompleted,
              let target = med.goalProgressTarget else {
            return "No goal set"
        }
        return "\(completed)/\(target)"
    }
    
    var hasGoal: Bool {
        med.goalProgressTarget != nil
    }
    
    var body: some View {
        if isSecondary {
            Text(hasGoal ? "Goal: \(progressText)" : "No goal")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            VStack {
                Text("Goal Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if hasGoal {
                    Text(progressText)
                        .font(.title2)
                        .bold()
                } else {
                    Text("No Goal")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AdherenceStreakView: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var streakText: String {
        guard let streak = med.adherenceStreak, streak > 0 else {
            return "0"
        }
        return "\(streak)"
    }
    
    var hasGoal: Bool {
        med.goalProgressTarget != nil
    }
    
    var body: some View {
        if isSecondary {
            if hasGoal {
                Text("🔥 \(streakText) day streak")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("No goal set")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack {
                if hasGoal {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text(streakText)
                            .font(.title)
                            .bold()
                    }
                } else {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("No Goal")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Prescription-Specific Widget Displays

struct DailyAverageSinceRefill: View {
    var med: MedEntity
    var logs: [MedLog]
    var isSecondary: Bool = false
    
    var totalSinceRefill: Double {
        guard med.medicationType == .prescription,
              let lastFilled = med.lastFilledOn else { return 0 }
        return logs.filter { log in
            !log.isRefill && log.timestamp >= lastFilled
        }
        .reduce(0) { $0 + abs($1.mgIntake) }
    }
    
    var daysSinceRefill: Double {
        guard let lastFilled = med.lastFilledOn else { return 1 }
        let days = Date().timeIntervalSince(lastFilled) / 86400
        return max(days, 1)
    }
    
    var dailyAverage: Double {
        totalSinceRefill / daysSinceRefill
    }
    
    var valueText: String {
        "\(formatNumber(dailyAverage))mg"
    }
    
    var body: some View {
        if isSecondary {
            if med.medicationType == .prescription {
                Text("Avg since refill: \(valueText)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("N/A for non-Rx")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack {
                Text("Avg Since Refill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if med.medicationType == .prescription {
                    Text(valueText)
                        .font(.title2)
                        .bold()
                    Text("per day")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("N/A")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DaysUntilRefill: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    private var nextFillDateFormatted: String {
        guard let nextFill = med.nextFillDate else { return "--" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: nextFill)
    }
    
    private var daysShort: String {
        "\(med.daysUntilRefill)d"
    }
    
    private var daysFull: String {
        "\(med.daysUntilRefill) days"
    }

    var body: some View {
        if isSecondary {
            if med.medicationType == .prescription {
                Text("Refill in \(daysShort)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("N/A for non-Rx")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack {
                Text("Days Until Refill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if med.medicationType == .prescription {
                    Text(daysFull)
                        .font(.title2)
                        .bold()
                    Text(nextFillDateFormatted)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("N/A")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct NextScheduledDose: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var body: some View {
        if isSecondary {
            Text("Next dose tracking coming soon")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            VStack {
                Text("Next Scheduled Dose")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Coming Soon")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DosesLeftToday: View {
    var med: MedEntity
    var logs: [MedLog]
    var isSecondary: Bool = false
    
    var dosesLeftText: String {
        guard let target = med.goalProgressTarget,
              let completed = med.goalProgressCompleted,
              med.goalProgressTarget != nil else {
            return "--"
        }
        let remaining = max(0, target - completed)
        return "\(remaining)"
    }
    
    var hasGoal: Bool {
        med.goalProgressTarget != nil
    }
    
    var body: some View {
        if isSecondary {
            if hasGoal {
                Text("Left today: \(dosesLeftText)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("No goal set")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack {
                Text("Doses Left Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if hasGoal {
                    Text(dosesLeftText)
                        .font(.title)
                        .bold()
                } else {
                    Text("No Goal")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct RefillsRemaining: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var refillText: String {
        guard let refills = med.refillsRemaining else {
            return "Unknown"
        }
        return "\(refills)"
    }
    
    var body: some View {
        if isSecondary {
            if med.medicationType == .prescription {
                Text("Refills: \(refillText)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("N/A for non-Rx")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack {
                Text("Refills Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if med.medicationType == .prescription {
                    Text(refillText)
                        .font(.title)
                        .bold()
                } else {
                    Text("N/A")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Non-Prescription Specific Widget Displays

struct BottleQuantityRemaining: View {
    var med: MedEntity
    var isSecondary: Bool = false
    
    var valueText: String {
        formatNumber(med.pillsRemaining)
    }
    
    var body: some View {
        if isSecondary {
            Text("Bottle: \(valueText)")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            VStack {
                Text("Bottle Quantity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title)
                    .bold()
                if med.medicationType == .nonPrescription {
                    Text("servings left")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

