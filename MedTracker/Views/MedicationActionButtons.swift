//
//  MedicationActionButtons.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import SwiftData
import SwiftUI

struct MedicationActionButtons: View {
    
    var med: Med
    @Binding var customDoseSheetPresented: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // On smaller screens: two columns grid layout
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                LazyVGrid(columns: columns, spacing: 12) {
                    buttonHalfDose
                    buttonFullDose
                    buttonCustom
                    if med.medicationType == .prescription {
                        buttonRefillRx
                    } else {
                        buttonRestockBottle
                    }
                }
            } else {
                // On larger screens: horizontal layout as before
                HStack(spacing: 12) {
                    buttonHalfDose
                    buttonFullDose
                    buttonCustom
                    if med.medicationType == .prescription {
                        buttonRefillRx
                    } else {
                        buttonRestockBottle
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Buttons
    
    private var buttonHalfDose: some View {
        Button(action: takeHalfMedication) {
            HStack {
                Image(systemName: "capsule.righthalf.filled")
                Text("Half Dose (\(med.mgPerPill / 2, specifier: "%.1f")mg)")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var buttonFullDose: some View {
        Button(action: takeFullMedication) {
            HStack {
                Image(systemName: "capsule.fill")
                Text("Full Dose (\(med.mgPerPill, specifier: "%.1f")mg)")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var buttonCustom: some View {
        Button(action: { customDoseSheetPresented.toggle() }) {
            HStack {
                Image(systemName: "capsule.on.capsule")
                Text("Custom")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var buttonRefillRx: some View {
        Button(action: refillMedication) {
            HStack {
                Image(systemName: "pills.fill")
                Text("Refill Rx")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var buttonRestockBottle: some View {
        Button(action: restockBottle) {
            HStack {
                Image(systemName: "cart.fill")
                Text("Restock Bottle")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Actions
    
    private func takeHalfMedication() {
        do {
            try med.takeMedication(dose: 0.5, unit: .pill)
        } catch {
            print("Error taking half medication: \(error)")
        }
    }
    
    private func takeFullMedication() {
        do {
            try med.takeMedication() // Defaults to 1 pill
        } catch {
            print("Error taking full medication: \(error)")
        }
    }
    
    private func refillMedication() {
        do {
            try med.refillMedication()
        } catch {
            print("Error refilling medication: \(error)")
        }
    }
    
    private func restockBottle() {
        do {
            try med.restockBottle(quantity: med.initialPillCount)
        } catch {
            print("Error restocking bottle: \(error)")
        }
    }
}
