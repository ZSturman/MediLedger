//
//  MedicationLogExporter.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/28/25.
//

import Foundation
import SwiftUI

enum ExportFormat {
    case csv
    case json
}

struct MedicationLogExporter {
    
    // MARK: - Export Single Medication Logs
    
    /// Exports logs for a single medication
    static func exportLogs(for med: Med, format: ExportFormat) -> URL? {
        switch format {
        case .csv:
            return exportCSV(for: [med])
        case .json:
            return exportJSON(for: [med])
        }
    }
    
    // MARK: - Export Multiple Medications Logs
    
    /// Exports logs for multiple medications
    static func exportLogs(for meds: [Med], format: ExportFormat) -> URL? {
        switch format {
        case .csv:
            return exportCSV(for: meds)
        case .json:
            return exportJSON(for: meds)
        }
    }
    
    // MARK: - CSV Export
    
    private static func exportCSV(for meds: [Med]) -> URL? {
        var csvString = "Medication Name,Medication Type,Log Date,Time,Intake (mg),Total Remaining (mg),Action Type\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        for med in meds {
            let logs = med.unwrappedLog.sorted { $0.timestamp < $1.timestamp }
            
            for log in logs {
                let medicationName = med.name.replacingOccurrences(of: ",", with: ";")
                let medicationType = med.medicationType.rawValue
                let date = dateFormatter.string(from: log.timestamp)
                let time = timeFormatter.string(from: log.timestamp)
                let intake = log.mgIntake
                let remaining = log.totalMgRemaining
                let actionType = log.isRefill ? "Refill/Restock" : "Dose Taken"
                
                csvString += "\"\(medicationName)\",\(medicationType),\(date),\(time),\(intake),\(remaining),\(actionType)\n"
            }
        }
        
        return saveToTemporaryFile(content: csvString, filename: generateFilename(format: "csv", medCount: meds.count))
    }
    
    // MARK: - JSON Export
    
    private static func exportJSON(for meds: [Med]) -> URL? {
        var exportData: [[String: Any]] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for med in meds {
            let logs = med.unwrappedLog.sorted { $0.timestamp < $1.timestamp }
            
            for log in logs {
                let logDict: [String: Any] = [
                    "medicationId": med.id,
                    "medicationName": med.name,
                    "medicationType": med.medicationType.rawValue,
                    "timestamp": dateFormatter.string(from: log.timestamp),
                    "mgIntake": log.mgIntake,
                    "totalMgRemaining": log.totalMgRemaining,
                    "actionType": log.isRefill ? "refill" : "dose",
                    "pillsIntake": log.mgIntake / med.mgPerPill,
                    "pillsRemaining": log.totalMgRemaining / med.mgPerPill
                ]
                exportData.append(logDict)
            }
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return saveToTemporaryFile(content: jsonString, filename: generateFilename(format: "json", medCount: meds.count))
    }
    
    // MARK: - Helper Methods
    
    private static func saveToTemporaryFile(content: String, filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    private static func generateFilename(format: String, medCount: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        if medCount == 1 {
            return "medication_logs_\(dateString).\(format)"
        } else {
            return "medication_logs_all_\(dateString).\(format)"
        }
    }
}

// MARK: - SwiftUI Share Sheet Helper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onDismiss: (() -> Void)?
    
    init(items: [Any], onDismiss: (() -> Void)? = nil) {
        self.items = items
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
