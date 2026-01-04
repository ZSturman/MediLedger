//
//  MedicationGoalConfigView.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import SwiftUI
import SwiftData

struct MedicationGoalConfigView: View {
    @Bindable var med: Med
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var hasGoal: Bool = false
    @State private var goalTargetDoses: Double = 1
    @State private var goalPeriod: GoalPeriod = .perDay
    @State private var goalSpecificDays: Set<Weekday> = []
    @State private var goalStartDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Intake Goal", isOn: $hasGoal)
                    
                    if hasGoal {
                        HStack {
                            Text("Target Doses:")
                            Spacer()
                            Stepper("\(Int(goalTargetDoses))", value: $goalTargetDoses, in: 1...10, step: 1)
                        }
                        
                        Picker("Period", selection: $goalPeriod) {
                            ForEach(GoalPeriod.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if goalPeriod == .perWeek {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Specific Days (Optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    ForEach(Weekday.allCases) { day in
                                        Button(action: {
                                            if goalSpecificDays.contains(day) {
                                                goalSpecificDays.remove(day)
                                            } else {
                                                goalSpecificDays.insert(day)
                                            }
                                        }) {
                                            Text(day.shortName)
                                                .font(.caption)
                                                .frame(minWidth: 36)
                                                .padding(.vertical, 6)
                                                .background(goalSpecificDays.contains(day) ? Color.accentColor : Color.gray.opacity(0.2))
                                                .foregroundColor(goalSpecificDays.contains(day) ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        DatePicker("Goal Start Date", selection: $goalStartDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Intake Goal")
                } footer: {
                    if hasGoal {
                        Text("Track your medication adherence with a custom goal. You'll see progress information.")
                    } else {
                        Text("Set a goal to track how consistently you take this medication.")
                    }
                }
            }
            .navigationTitle("Configure Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                }
            }
            .onAppear {
                loadCurrentGoal()
            }
        }
    }
    
    private func loadCurrentGoal() {
        if let goal = med.intakeGoal {
            hasGoal = true
            goalTargetDoses = goal.targetDoses
            goalPeriod = goal.period
            goalSpecificDays = goal.specificDays ?? []
            goalStartDate = goal.startDate ?? Date()
        } else {
            hasGoal = false
        }
    }
    
    private func saveGoal() {
        if hasGoal {
            med.intakeGoal = IntakeGoal(
                targetDoses: goalTargetDoses,
                period: goalPeriod,
                specificDays: goalSpecificDays.isEmpty ? nil : goalSpecificDays,
                timesOfDay: nil,
                startDate: goalStartDate
            )
        } else {
            med.intakeGoal = nil
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving goal: \(error)")
        }
        
        dismiss()
    }
}

struct MedicationGoalStatusCard: View {
    @Bindable var med: Med
    @State private var showingGoalConfig = false
    
    var goalProgressData: (completed: Int, target: Int)? {
        med.goalProgress()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Intake Goal")
                    .font(.title3)
                    .bold()
                Spacer()
                Button(action: { showingGoalConfig = true }) {
                    Text(med.intakeGoal == nil ? "Set Goal" : "Edit Goal")
                        .font(.subheadline)
                }
            }
            
            if let goal = med.intakeGoal, let progress = goalProgressData {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress:")
                        Spacer()
                        Text("\(progress.completed)/\(progress.target)")
                            .font(.title2)
                            .bold()
                        Text(goal.period.rawValue.lowercased())
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(progress.completed), total: Double(progress.target))
                        .tint(progress.completed >= progress.target ? .green : .accentColor)
                    
                    if let days = goal.specificDays, !days.isEmpty {
                        HStack {
                            Text("Days:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                ForEach(Array(days).sorted(by: { $0.rawValue < $1.rawValue })) { day in
                                    Text(day.shortName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No goal set. Tap 'Set Goal' to track your adherence.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 2, y: 1)
        .sheet(isPresented: $showingGoalConfig) {
            MedicationGoalConfigView(med: med)
        }
    }
}
