//
//  NoMedicationSelectedWidgetView.swift
//  MedTrackerWidgetExtension
//
//  Created by Zachary Sturman on 3/30/25.
//

import Foundation
import WidgetKit
import SwiftUI

struct NoMedicationSelectedWidgetView: View {
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "pills")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 4) {
                Text("No Medication")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text("Tap to configure")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
