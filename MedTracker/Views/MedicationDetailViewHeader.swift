//
//  MedicationDetailViewHeader.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import SwiftData
import SwiftUI

struct MedicationDetailViewHeader: View {
    var med: Med

    // Compute the number of days until the next refill
    private var daysUntilRefill: Int? {
        guard let nextFill = med.nextFillDate else { return nil }
        let now = Date()
        let diff = Calendar.current.dateComponents([.day], from: now, to: nextFill).day ?? 0
        return max(diff, 0)
    }
    
    // Filter today's logs that are not refill logs
    private var todayLogs: [MedLog] {
        med.unwrappedLog.filter { Calendar.current.isDateInToday($0.timestamp) && !$0.isRefill }
    }
    
    // Total pills taken today (mg taken divided by mg per pill)
    private var pillsTakenToday: Double {
        let totalMgTaken = todayLogs.reduce(0) { $0 + $1.mgIntake }
        return totalMgTaken / med.mgPerPill
    }
    
    // The last non-refill log overall
    private var lastNonRefillLog: MedLog? {
        med.unwrappedLog.last(where: { !$0.isRefill })
    }
    
    // The last log from today (if any)
    private var lastTodayLog: MedLog? {
        todayLogs.last
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Medication name and description
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(med.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let desc = med.desc, !desc.isEmpty {
                        Text(desc)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            
            // Days until next refill and pills per day left (prescription only)
            if med.medicationType == .prescription {
                HStack {
                    if let days = daysUntilRefill {
                        Text("Days until refill: \(days)")
                            .font(.subheadline)
                    }
                    Spacer()
                    Text("Pills/day left: \(med.pillsPerDayLeft, specifier: "%.1f")")
                        .font(.subheadline)
                }
                
                HStack {
                    if let lastFilled = med.lastFilledOn {
                        Text("Last filled: \(lastFilled, format: Date.FormatStyle(date: .numeric, time: .shortened))")
                            .font(.subheadline)
                    }
                    Spacer()
                    if let nextFill = med.nextFillDate {
                        Text("Next fill: \(nextFill, format: Date.FormatStyle(date: .numeric, time: .shortened))")
                            .font(.subheadline)
                    }
                }
            }
            
            
            // Last intake log (if it’s not a refill)
            if let lastNonRefillLog = lastNonRefillLog {
                Text("Last intake: \(lastNonRefillLog.mgIntake, specifier: "%.1f") mg at \(lastNonRefillLog.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))")
                    .font(.subheadline)
            }
            
            // Today's intake summary
            if !todayLogs.isEmpty, let lastTodayLog = lastTodayLog {
                Text("Today: \(pillsTakenToday, specifier: "%.1f") pills taken, last at \(lastTodayLog.timestamp, format: Date.FormatStyle(time: .shortened))")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }
}
