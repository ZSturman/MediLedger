//
//  MedicationDetailView.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
//

import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    var med: Med
    
    // For displaying the custom dose sheet.
    @State private var customDoseSheetPresented: Bool = false
    @State private var shareSheetURL: URL?
    @State private var showShareSheet: Bool = false


    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MedicationDetailViewHeader(med: med)
                    Divider()
                    MedicationActionButtons(med: med, customDoseSheetPresented: $customDoseSheetPresented)
                    MedicationDescriptionMainContent(med: med)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(med.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        exportMedicationLogs(format: .csv)
                    } label: {
                        Label("Export as CSV", systemImage: "doc.text")
                    }
                    
                    Button {
                        exportMedicationLogs(format: .json)
                    } label: {
                        Label("Export as JSON", systemImage: "curlybraces")
                    }
                } label: {
                    Label("Export Logs", systemImage: "square.and.arrow.up")
                }
                .disabled(med.unwrappedLog.isEmpty)
            }
        }
        .sheet(isPresented: $customDoseSheetPresented) {
            MedicationCustomDoseForm(med: med, customDoseSheetPresented: $customDoseSheetPresented)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareSheetURL {
                ShareSheet(items: [url]) {
                    shareSheetURL = nil
                }
            }
        }
    }
    
    private func exportMedicationLogs(format: ExportFormat) {
        if let fileURL = MedicationLogExporter.exportLogs(for: med, format: format) {
            shareSheetURL = fileURL
            showShareSheet = true
        }
    }
    


}

