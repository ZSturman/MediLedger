//
//  ContentView.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var meds: [Med]
    
    @State private var newMedicationSheetIsPresented: Bool = false
    @State private var selectedMed: Med?  // Added selection state
    @State private var showExportMenu: Bool = false
    @State private var shareSheetURL: URL?
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMed) { // Bind the selection
                ForEach(meds) { med in
                    NavigationLink(value: med) {  // Use the value initializer
                        VStack(alignment: .leading) {
                            Text(med.name)
                                .font(.headline)
                            if let lastFilled = med.lastFilledOn {
                                HStack {
                                    Text("Last filled:")
                                    Text(lastFilled, format: Date.FormatStyle(date: .numeric, time: .omitted))
                                        .foregroundColor(.secondary)
                                }
                            }
                            HStack {
                                Text("Pills/Day Left:")
                                Text("\(med.pillsPerDayLeft, specifier: "%.1f")")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(med)
                            }
                        } label: {
                            Text("Delete")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Take") {
                            takeMedication(med)
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(med)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
  
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Menu {
                        Button {
                            exportAllLogs(format: .csv)
                        } label: {
                            Label("Export All as CSV", systemImage: "doc.text")
                        }
                        
                        Button {
                            exportAllLogs(format: .json)
                        } label: {
                            Label("Export All as JSON", systemImage: "curlybraces")
                        }
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }
                    .disabled(meds.isEmpty)
                }
                ToolbarItem {
                    Button {
                        newMedicationSheetIsPresented.toggle()
                    } label: {
                        Label("Add Medication", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let med = selectedMed {
                MedicationDetailView(med: med)
            } else {
                Text("Select an item")
            }
        }
        .sheet(isPresented: $newMedicationSheetIsPresented) {
            NewMedicationSheet()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareSheetURL {
                ShareSheet(items: [url]) {
                    shareSheetURL = nil
                }
            }
        }
    }
    
    private func exportAllLogs(format: ExportFormat) {
        guard !meds.isEmpty else { return }
        
        if let fileURL = MedicationLogExporter.exportLogs(for: meds, format: format) {
            shareSheetURL = fileURL
            showShareSheet = true
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(meds[index])
            }
        }
    }
    
    private func takeMedication(_ med: Med) {
        withAnimation {
            do {
                try med.takeMedication()
            } catch {
                print("Error taking medication: \(error)")
            }
        }
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Med.self, inMemory: true)
//}
