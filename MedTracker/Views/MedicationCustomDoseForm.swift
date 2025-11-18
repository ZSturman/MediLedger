//
//  MedicationCustomDoseForm.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import SwiftData
import SwiftUI

struct MedicationCustomDoseForm: View {
    
    var med: Med
    @Binding var customDoseSheetPresented: Bool
    
    @State private var customDoseValue: Double = 0
    @State private var customDoseUnit: DosageUnit = .pill
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Custom Dose")) {
                    HStack {
                        Text("Dose Amount:")
                        TextField("Enter amount", value: $customDoseValue, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    Picker("Unit", selection: $customDoseUnit) {
                        ForEach(DosageUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Custom Dose")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        customDoseSheetPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        takeCustomDose()
                        customDoseSheetPresented = false
                    }
                }
            }
        }
    }
    
    private func takeCustomDose() {
        do {
            try med.takeMedication(dose: customDoseValue, unit: customDoseUnit)
        } catch {
            print("Error taking custom dose: \(customDoseValue) \(customDoseUnit). Error: \(error)")
        }
    }
}
