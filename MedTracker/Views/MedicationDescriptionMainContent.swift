//
//  MedicationDescriptionMainContent.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import SwiftData
import SwiftUI

struct MedicationDescriptionMainContent: View {
    @Bindable var med: Med
    
    @State private var selectedHistoryFilter: HistoryFilter = .all
    @State private var logsToShow: Int = 20
    private let logsPageSize: Int = 20
    
    @State private var editingLog: MedLog?
    @State private var editTimestamp: Date = Date()
    @State private var editMgIntake: Double = 0

    // Unit selection for viewing and editing
    private enum DisplayUnit: String, CaseIterable { case mg = "mg", pills = "pills" }
    @State private var displayUnit: DisplayUnit = .mg
    @State private var editDisplayUnit: DisplayUnit = .mg
    @State private var editDose: Double = 0
    
    // Remaining amount editing
    @State private var remainingUnit: DosageUnit = .pill
    @State private var remainingValue: Double = 0
    @State private var showEditRemainingSheet: Bool = false

    // Formatting and conversion helpers
    private func cleanNumber(_ value: Double, maxFractionDigits: Int = 2) -> String {
        if value.isNaN || value.isInfinite { return "0" }
        let intPart = floor(value)
        if value == intPart { return String(Int(intPart)) }
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = maxFractionDigits
        return f.string(from: NSNumber(value: value)) ?? String(value)
    }
    private func pillsFromMg(_ mg: Double) -> Double { guard med.mgPerPill > 0 else { return 0 }; return mg / med.mgPerPill }
    private func mgFromPills(_ pills: Double) -> Double { return pills * med.mgPerPill }
    
    private func convertRemainingToMg(_ amount: Double, unit: DosageUnit) -> Double {
        switch unit {
        case .mg:
            return amount
        case .pill:
            return amount * med.mgPerPill
        case .ml, .spray, .drop, .puff, .application:
            return amount * med.mgPerPill
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var todaysLogs: [MedLog] {
        med.unwrappedLog.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: Date()) }
    }
    
    var filteredLogs: [MedLog] {
        let now = Date()
        switch selectedHistoryFilter {
        case .all:
            return med.unwrappedLog.sorted { $0.timestamp > $1.timestamp }
        case .week:
            guard let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return med.unwrappedLog.sorted { $0.timestamp > $1.timestamp } }
            return med.unwrappedLog
                .filter { $0.timestamp >= oneWeekAgo }
                .sorted { $0.timestamp > $1.timestamp }
        case .month:
            guard let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) else { return med.unwrappedLog.sorted { $0.timestamp > $1.timestamp } }
            return med.unwrappedLog
                .filter { $0.timestamp >= oneMonthAgo }
                .sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    var groupedLimitedLogs: [(date: Date, logs: [MedLog])] {
        let limited = Array(filteredLogs.prefix(logsToShow))
        let grouped = Dictionary(grouping: limited) { log in
            Calendar.current.startOfDay(for: log.timestamp)
        }
        let sortedDays = grouped.keys.sorted(by: >)
        return sortedDays.map { day in
            let dayLogs = (grouped[day] ?? []).sorted { $0.timestamp > $1.timestamp }
            return (date: day, logs: dayLogs)
        }
    }
    
    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        ScrollView {
            VStack(spacing: 24) {
                // Goal Status Card (if goal is set or user wants to set one)
                MedicationGoalStatusCard(med: med)
                
                // Medication Info Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Medication Info")
                        .font(.title2).bold()
                        .padding(.bottom, 2)
                    
                    Group {
                        LabeledContent(content: {
                            TextField("Name", text: $med.name)
                                .font(.body)
                                .textFieldStyle(.roundedBorder)
                        }, label: { Text("Name") })
                        
                        LabeledContent(content: {
                            if let descBinding = Binding($med.desc) {
                                TextField("Description", text: descBinding, axis: .vertical)
                                    .font(.body)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...4)
                            } else {
                                Button("Add Description") {
                                    med.desc = ""
                                }
                            }
                        }, label: { Text("Description") })
                        
                        LabeledContent(content: {
                            Picker("Type", selection: $med.medicationType) {
                                ForEach(MedicationType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }, label: { Text("Type") })
                        
                        LabeledContent(content: {
                            Picker("Form", selection: $med.pillForm) {
                                ForEach(MedicationForm.allCases) { form in
                                    Text(form.rawValue).tag(form)
                                }
                            }
                            .pickerStyle(.menu)
                        }, label: { Text("Form") })
                        
                        LabeledContent(content: {
                            TextField("Dosage (mg)", value: $med.mgPerPill, format: .number)
                                .font(.body)
                                .textFieldStyle(.roundedBorder)
                        }, label: { Text("Dosage (mg)") })
                        
                        LabeledContent(content: {
                            HStack {
                                if let dailyDosageBinding = Binding($med.dailyDosage) {
                                    TextField("Amount", value: dailyDosageBinding, format: .number)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 100)
                                    
                                    if let unitBinding = Binding($med.dailyDosageUnit) {
                                        Picker("Unit", selection: unitBinding) {
                                            ForEach(DosageUnit.allCases) { unit in
                                                Text(unit.rawValue).tag(unit)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                } else {
                                    Button("Set Daily Dosage") {
                                        med.dailyDosage = 1.0
                                        med.dailyDosageUnit = .pill
                                    }
                                }
                            }
                        }, label: { Text("Daily Dosage") })
                        
                        if med.medicationType == .prescription {
                            Divider()
                            
                            Text("Prescription Details")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            LabeledContent(content: {
                                if let lastFilled = Binding($med.lastFilledOn) {
                                    DatePicker("", selection: lastFilled, displayedComponents: .date)
                                        .labelsHidden()
                                } else {
                                    Button("Set Date") {
                                        med.lastFilledOn = Date()
                                    }
                                }
                            }, label: { Text("Last Filled") })
                            
                            LabeledContent(content: {
                                if let daysSupply = Binding($med.numberOfDaysSupply) {
                                    TextField("Number of Days", value: daysSupply, format: .number)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Set Days Supply") {
                                        med.numberOfDaysSupply = 30
                                    }
                                }
                            }, label: { Text("Days Supply") })
                            
                            LabeledContent(content: {
                                if let prescriberBinding = Binding($med.prescriberName) {
                                    TextField("Prescriber", text: prescriberBinding)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Add Prescriber") {
                                        med.prescriberName = ""
                                    }
                                }
                            }, label: { Text("Prescriber") })
                            
                            LabeledContent(content: {
                                if let pharmacyBinding = Binding($med.pharmacyName) {
                                    TextField("Pharmacy", text: pharmacyBinding)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Add Pharmacy") {
                                        med.pharmacyName = ""
                                    }
                                }
                            }, label: { Text("Pharmacy") })
                            
                            LabeledContent(content: {
                                if let rxBinding = Binding($med.rxNumber) {
                                    TextField("Rx Number", text: rxBinding)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Add Rx Number") {
                                        med.rxNumber = ""
                                    }
                                }
                            }, label: { Text("Rx Number") })
                            
                            LabeledContent(content: {
                                if let refillsBinding = Binding($med.refillsRemaining) {
                                    Stepper("\(refillsBinding.wrappedValue)", value: refillsBinding, in: 0...99)
                                } else {
                                    Button("Set Refills") {
                                        med.refillsRemaining = 0
                                    }
                                }
                            }, label: { Text("Refills Remaining") })
                        }
                        
                        if med.medicationType == .nonPrescription {
                            Divider()
                            
                            Text("Product Details")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            LabeledContent(content: {
                                if let brandBinding = Binding($med.brandName) {
                                    TextField("Brand", text: brandBinding)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Add Brand") {
                                        med.brandName = ""
                                    }
                                }
                            }, label: { Text("Brand Name") })
                            
                            LabeledContent(content: {
                                if let typeBinding = Binding($med.supplementType) {
                                    TextField("Supplement Type", text: typeBinding)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Add Type") {
                                        med.supplementType = ""
                                    }
                                }
                            }, label: { Text("Supplement Type") })
                            
                            LabeledContent(content: {
                                if let servingSizeBinding = Binding($med.servingSize) {
                                    Stepper("\(servingSizeBinding.wrappedValue)", value: servingSizeBinding, in: 1...10)
                                } else {
                                    Button("Set Serving Size") {
                                        med.servingSize = 1
                                    }
                                }
                            }, label: { Text("Serving Size") })
                            
                            LabeledContent(content: {
                                if let servingsBinding = Binding($med.servingsPerContainer) {
                                    TextField("Servings", value: servingsBinding, format: .number)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Set Servings") {
                                        med.servingsPerContainer = 30
                                    }
                                }
                            }, label: { Text("Servings/Container") })
                            
                            LabeledContent(content: {
                                if let locationBinding = Binding($med.purchaseLocation) {
                                    TextField("Location", text: locationBinding)
                                        .font(.body)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Button("Add Purchase Location") {
                                        med.purchaseLocation = ""
                                    }
                                }
                            }, label: { Text("Purchase Location") })
                            
                            LabeledContent(content: {
                                if let expirationBinding = Binding($med.expirationDate) {
                                    DatePicker("", selection: expirationBinding, displayedComponents: .date)
                                        .labelsHidden()
                                } else {
                                    Button("Set Expiration") {
                                        med.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
                                    }
                                }
                            }, label: { Text("Expiration Date") })
                        }
                        
                        Divider()
                        
                        Text("Scheduling")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        LabeledContent(content: {
                            if let nextDoseBinding = Binding($med.nextDoseTime) {
                                DatePicker("", selection: nextDoseBinding, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            } else {
                                Button("Set Next Dose Time") {
                                    med.nextDoseTime = Date()
                                }
                            }
                        }, label: { Text("Next Dose Time") })
                        
                        LabeledContent(content: {
                            TextField("Initial Pill Count", value: $med.initialPillCount, format: .number)
                                .font(.body)
                                .textFieldStyle(.roundedBorder)
                        }, label: { Text("Initial Pill Count") })
                        
                        LabeledContent(content: {
                            Button(action: {
                                remainingUnit = .pill
                                remainingValue = pillsFromMg(med.totalMgRemaining)
                                showEditRemainingSheet = true
                            }) {
                                HStack {
                                    Text("\(cleanNumber(med.totalMgRemaining)) mg")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.title3)
                                }
                            }
                            .buttonStyle(.plain)
                        }, label: { Text("Remaining") })
                    }
                    .padding(.vertical, 2)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(radius: 2, y: 1)
                
                // Logs Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Medication Log")
                        .font(.title2).bold()
                    HStack(spacing: 12) {
                        Picker("History Filter", selection: $selectedHistoryFilter) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Units", selection: $displayUnit) {
                            Text("mg").tag(DisplayUnit.mg)
                            Text("pills").tag(DisplayUnit.pills)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    }
                    
                    if filteredLogs.isEmpty {
                        Text("No logs available for this period.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(groupedLimitedLogs, id: \.date) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                                        .font(.headline)
                                    VStack(spacing: 0) {
                                        ForEach(group.logs, id: \.id) { log in
                                            HStack {
                                                Text("\(displayUnit == .mg ? "\(cleanNumber(log.mgIntake)) mg" : "\(cleanNumber(pillsFromMg(log.mgIntake))) pills") at \(log.timestamp, format: Date.FormatStyle(date: .omitted, time: .shortened))")
                                                    .font(.subheadline)
                                                Spacer()
                                               
                                                Button {
                                                    editingLog = log
                                                    editTimestamp = log.timestamp
                                                    editDisplayUnit = displayUnit
                                                    if editDisplayUnit == .mg {
                                                        editDose = log.mgIntake
                                                    } else {
                                                        editDose = pillsFromMg(log.mgIntake)
                                                    }
                                                } label: {
                                                    Image(systemName: "ellipsis")
                                                }
                                                
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 4)
                                            if log.id != group.logs.last?.id {
                                                Divider()
                                            }
                                        }
                                    }
                                    .background(.thickMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                            }

                            if filteredLogs.count > logsToShow {
                                Button("Load More") {
                                    logsToShow += logsPageSize
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(radius: 2, y: 1)
            }
            .padding(isCompact ? 12 : 32)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onChange(of: selectedHistoryFilter) { _, _ in
            logsToShow = logsPageSize
        }
        .sheet(isPresented: $showEditRemainingSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Update Remaining Amount")) {
                        HStack {
                            Text("Amount:")
                            Spacer()
                            TextField("", value: $remainingValue, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                        
                        Picker("Unit", selection: $remainingUnit) {
                            ForEach(DosageUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Text("Equals:")
                            Spacer()
                            Text("\(convertRemainingToMg(remainingValue, unit: remainingUnit), specifier: "%.1f") mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Edit Remaining")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showEditRemainingSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newMgValue = convertRemainingToMg(remainingValue, unit: remainingUnit)
                            med.totalMgRemaining = newMgValue
                            showEditRemainingSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editingLog) { log in
            NavigationStack {
                VStack {
                    Text("Editing a log will not update medication quantities.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Form {
                        Section("Details") {
                            DatePicker("Date", selection: $editTimestamp, displayedComponents: .date)
                            DatePicker("Time", selection: $editTimestamp, displayedComponents: .hourAndMinute)

                            // Amount + inline unit menu with +/- buttons
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Picker("", selection: $editDisplayUnit) {
                                        Text("mg").tag(DisplayUnit.mg)
                                        Text("pills").tag(DisplayUnit.pills)
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    Spacer()
                                    
                                    // Decrement button
                                    Button(action: {
                                        let increment = editDisplayUnit == .pills ? 0.5 : med.mgPerPill / 2
                                        editDose = max(0, editDose - increment)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    TextField("Amount", value: $editDose, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    // Increment button
                                    Button(action: {
                                        let increment = editDisplayUnit == .pills ? 0.5 : med.mgPerPill / 2
                                        editDose += increment
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if editDisplayUnit == .pills && med.mgPerPill == 0 {
                                Text("Set Dosage (mg) in Medication Info to use pills.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            Button("Delete Log", role: .destructive) {
                                modelContext.delete(log)
                                try? modelContext.save()
                                editingLog = nil
                            }
                        }
                    }
                }
                .navigationTitle("Edit Log")
                .onChange(of: editDisplayUnit) { oldUnit, newUnit in
                    if oldUnit == .mg && newUnit == .pills {
                        editDose = pillsFromMg(editDose)
                    } else if oldUnit == .pills && newUnit == .mg {
                        editDose = mgFromPills(editDose)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingLog = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newMg = editDisplayUnit == .mg ? editDose : mgFromPills(editDose)
                            log.timestamp = editTimestamp
                            log.mgIntake = newMg
                            try? modelContext.save()
                            editingLog = nil
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
