//
//  NewMedicationSheet.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
//

import SwiftUI
import SwiftData

struct NewMedicationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Basic Details
    @State private var name: String = ""
    @State private var desc: String = ""
    @State private var medicationType: MedicationType = .prescription
    @State private var pillMg: Double = 20
    @State private var pillForm: String = ""

    // MARK: - Prescription-Specific
    @State private var lastFilledOn: Date = Date()
    @State private var manualNextFillOverride: Bool = false
    @State private var manualNextFillDate: Date = Date()
    @State private var numberOfDaysSupply: Double = 30
    @State private var initialPillCount: Double = 30
    @State private var prescriberName: String = ""
    @State private var pharmacyName: String = ""
    @State private var rxNumber: String = ""
    @State private var refillsRemaining: String = ""

    // MARK: - Non-Prescription Specific
    @State private var brandName: String = ""
    @State private var supplementType: String = ""
    @State private var servingSize: Int = 1
    @State private var servingsPerContainer: Int = 30
    @State private var purchaseLocation: String = ""
    @State private var expirationDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var hasExpirationDate: Bool = false

    // MARK: - Dosage & Supply
    @State private var dailyDosage: Double = 1
    @State private var dailyDosageUnit: DosageUnit = .pill
    @State private var totalMgRemaining: Double = 0
    @State private var differentFromRemaining: Bool = false

    // MARK: - Goal Tracking
    @State private var hasGoal: Bool = false
    @State private var goalTargetDoses: Int = 1
    @State private var goalPeriod: GoalPeriod = .perDay
    @State private var goalSpecificDays: Set<Weekday> = []
    @State private var goalStartDate: Date = Date()

    // MARK: - Progressive Disclosure
    @State private var showAdvancedPrescriptionInfo: Bool = false
    @State private var showAdvancedNonPrescriptionInfo: Bool = false

    var computedNextFillDate: Date {
        Calendar.current.date(byAdding: .day, value: Int(numberOfDaysSupply), to: lastFilledOn) ?? lastFilledOn
    }
    
    var nextFillDateWarning: Bool {
        manualNextFillOverride && !Calendar.current.isDate(manualNextFillDate, inSameDayAs: computedNextFillDate)
    }
    
    var finalNextFillDate: Date {
        manualNextFillOverride ? manualNextFillDate : computedNextFillDate
    }
    
    var computedTotalRemaining: Double {
        if medicationType == .prescription {
            return initialPillCount * pillMg
        } else {
            return Double(servingsPerContainer * servingSize) * pillMg
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Core Details (Always Visible)
                Section(header: Text("Basic Information")) {
                    TextField("Medication Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Description (optional)", text: $desc)
                    
                    Picker("Type", selection: $medicationType) {
                        ForEach(MedicationType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Strength & Form")) {
                    HStack {
                        Text("Strength (mg):")
                        Spacer()
                        TextField("", value: $pillMg, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Form (e.g., Tablet, Capsule, Gummy)", text: $pillForm)
                }
                
                // MARK: - Prescription-Specific Sections
                if medicationType == .prescription {
                    Section(header: Text("Refill Information")) {
                        DatePicker("Last Filled On", selection: $lastFilledOn, displayedComponents: .date)
                        
                        HStack {
                            Text("Days Supply:")
                            Spacer()
                            TextField("", value: $numberOfDaysSupply, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                        
                        HStack {
                            Text("Pills per Refill:")
                            Spacer()
                            TextField("", value: $initialPillCount, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                        
                        Toggle("Manually Set Next Fill Date", isOn: $manualNextFillOverride)
                            .accessibilityIdentifier("manualNextFillToggle")
                            .onChange(of: manualNextFillOverride) { _, newValue in
                                print("🔄 Toggle changed to: \(newValue)")
                            }
                        
                        if manualNextFillOverride {
                            DatePicker("Next Fill Date", selection: $manualNextFillDate, displayedComponents: .date)
                                .id("manualDatePicker")
                            if nextFillDateWarning {
                                Text("⚠️ Manually entered date differs from computed schedule")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        } else {
                            HStack {
                                Text("Next Fill Date")
                                Spacer()
                                Text(computedNextFillDate, format: Date.FormatStyle(date: .numeric, time: .omitted))
                                    .foregroundColor(.secondary)
                            }
                            .id("computedDateDisplay")
                        }
                    }
                    
                    DisclosureGroup("Advanced Prescription Details", isExpanded: $showAdvancedPrescriptionInfo) {
                        TextField("Prescriber Name", text: $prescriberName)
                        TextField("Pharmacy Name", text: $pharmacyName)
                        TextField("Rx Number", text: $rxNumber)
                        HStack {
                            Text("Refills Remaining:")
                            Spacer()
                            TextField("", text: $refillsRemaining)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                // MARK: - Non-Prescription Specific Sections
                if medicationType == .nonPrescription {
                    Section(header: Text("Product Information")) {
                        TextField("Brand Name (e.g., Advil, NatureMade)", text: $brandName)
                        TextField("Type (e.g., Vitamin D, Probiotic)", text: $supplementType)
                        
                        HStack {
                            Text("Serving Size:")
                            Spacer()
                            Stepper("\(servingSize)", value: $servingSize, in: 1...10)
                        }
                        
                        HStack {
                            Text("Servings per Bottle:")
                            Spacer()
                            TextField("", value: $servingsPerContainer, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    DisclosureGroup("Additional Details", isExpanded: $showAdvancedNonPrescriptionInfo) {
                        TextField("Purchase Location", text: $purchaseLocation)
                        
                        Toggle("Has Expiration Date", isOn: $hasExpirationDate)
                        if hasExpirationDate {
                            DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                        }
                    }
                }
                
                // MARK: - Dosage Details (Both Types)
                Section(header: Text("Daily Dosage (Optional)")) {
                    HStack {
                        Text("Target Daily Dosage:")
                        Spacer()
                        TextField("", value: $dailyDosage, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Unit", selection: $dailyDosageUnit) {
                        ForEach(DosageUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Supply Remaining
                Section(header: Text("Current Supply")) {
                    Toggle("Manually Enter Amount Remaining", isOn: $differentFromRemaining)
                    
                    if differentFromRemaining {
                        HStack {
                            Text("Remaining (mg):")
                            Spacer()
                            TextField("", value: $totalMgRemaining, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    } else {
                        HStack {
                            Text("Computed Remaining:")
                            Spacer()
                            Text("\(computedTotalRemaining, specifier: "%.1f") mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Goal Tracking (Both Types)
                DisclosureGroup("Intake Goal (Optional)", isExpanded: $hasGoal) {
                    Toggle("Set Intake Goal", isOn: $hasGoal)
                    
                    if hasGoal {
                        HStack {
                            Text("Target Doses:")
                            Spacer()
                            Stepper("\(goalTargetDoses)", value: $goalTargetDoses, in: 1...10)
                        }
                        
                        Picker("Period", selection: $goalPeriod) {
                            ForEach(GoalPeriod.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if goalPeriod == .perWeek {
                            VStack(alignment: .leading) {
                                Text("Specific Days (Optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
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
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(goalSpecificDays.contains(day) ? Color.accentColor : Color.gray.opacity(0.2))
                                                .foregroundColor(goalSpecificDays.contains(day) ? .white : .primary)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                        
                        DatePicker("Goal Start Date", selection: $goalStartDate, displayedComponents: .date)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addMedication() }
                        .disabled(name.isEmpty)
                }
            }
            .onChange(of: manualNextFillOverride) { oldValue, newValue in
                print("⚠️ manualNextFillOverride changed from \(oldValue) to \(newValue)")
            }
        }
    }
    
    private func addMedication() {
        withAnimation {
            let remaining = differentFromRemaining ? totalMgRemaining : computedTotalRemaining
            
            let goal: IntakeGoal? = hasGoal ? IntakeGoal(
                targetDoses: goalTargetDoses,
                period: goalPeriod,
                specificDays: goalSpecificDays.isEmpty ? nil : goalSpecificDays,
                timesOfDay: nil,
                startDate: goalStartDate
            ) : nil
            
            let newMedication = Med(
                name: name,
                desc: desc.isEmpty ? nil : desc,
                medicationType: medicationType,
                pillForm: pillForm.isEmpty ? nil : pillForm,
                lastFilledOn: medicationType == .prescription ? lastFilledOn : nil,
                nextFillDate: medicationType == .prescription ? finalNextFillDate : nil,
                totalMgRemaining: remaining,
                numberOfDaysSupply: medicationType == .prescription ? numberOfDaysSupply : nil,
                initialPillCount: initialPillCount,
                mgPerPill: pillMg,
                dailyDosage: dailyDosage > 0 ? dailyDosage : nil,
                dailyDosageUnit: dailyDosage > 0 ? dailyDosageUnit : nil,
                intakeGoal: goal,
                brandName: brandName.isEmpty ? nil : brandName,
                supplementType: supplementType.isEmpty ? nil : supplementType,
                servingSize: medicationType == .nonPrescription ? servingSize : nil,
                servingsPerContainer: medicationType == .nonPrescription ? servingsPerContainer : nil,
                purchaseLocation: purchaseLocation.isEmpty ? nil : purchaseLocation,
                expirationDate: hasExpirationDate ? expirationDate : nil,
                prescriberName: prescriberName.isEmpty ? nil : prescriberName,
                pharmacyName: pharmacyName.isEmpty ? nil : pharmacyName,
                rxNumber: rxNumber.isEmpty ? nil : rxNumber,
                refillsRemaining: Int(refillsRemaining)
            )
            
            modelContext.insert(newMedication)
        }
        dismiss()
    }
    
    private func cancel() {
        dismiss()
    }
}

