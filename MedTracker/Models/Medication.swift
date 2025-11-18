//
//  Medication.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Med {
    var id: String = UUID().uuidString
    var name: String = ""
    var desc: String?
    
    // MARK: - Medication Type & Core Details
    private var medicationTypeRaw: String = MedicationType.prescription.rawValue
    var pillForm: String?                               // NEW: "Tablet", "Capsule", "Gummy", etc.
    
    // MARK: - Date Information (Optional for non-prescription)
    var lastFilledOn: Date?                             // CHANGED: Optional for non-prescription
    var nextFillDate: Date?                             // CHANGED: Optional for non-prescription
    
    // MARK: - Supply Information
    var totalMgRemaining: Double = 0.0
    var numberOfDaysSupply: Double?                     // CHANGED: Optional for non-prescription
    var initialPillCount: Double = 0.0
    var mgPerPill: Double = 0.0
    
    // MARK: - Dosage Information
    var dailyDosage: Double?                            // NEW: Target doses per day (optional for PRN)
    private var dailyDosageUnitRaw: String?             // NEW: Unit for daily dosage (stored as raw value)
    
    // MARK: - Goal Tracking (for adherence and habit formation)
    var intakeGoalData: Data?                           // NEW: Encoded IntakeGoal struct
    
    // MARK: - Non-Prescription Specific
    var brandName: String?                              // NEW: "Advil", "NatureMade", etc.
    var supplementType: String?                         // NEW: "Vitamin D", "Probiotic", etc.
    var servingSize: Int?                               // NEW: e.g., 2 gummies per serving
    var servingsPerContainer: Int?                      // NEW: For restock estimation
    var purchaseLocation: String?                       // NEW: "Costco", "Amazon", etc.
    var expirationDate: Date?                           // NEW: Common for OTC/supplements
    
    // MARK: - Prescription Specific
    var prescriberName: String?                         // NEW: Doctor's name
    var pharmacyName: String?                           // NEW: Pharmacy name
    var rxNumber: String?                               // NEW: Prescription number
    var refillsRemaining: Int?                          // NEW: Number of refills left
    
    @Relationship(deleteRule: .cascade, inverse: \MedLog.med) var log: [MedLog]? = []
    
    var unwrappedLog: [MedLog] {
        log ?? []
    }
    
    // MARK: - Computed: MedicationType
    var medicationType: MedicationType {
        get {
            MedicationType(rawValue: medicationTypeRaw) ?? .prescription
        }
        set {
            medicationTypeRaw = newValue.rawValue
        }
    }
    
    // MARK: - Computed: DailyDosageUnit
    var dailyDosageUnit: DosageUnit? {
        get {
            guard let raw = dailyDosageUnitRaw else { return nil }
            return DosageUnit(rawValue: raw)
        }
        set {
            dailyDosageUnitRaw = newValue?.rawValue
        }
    }
    
    // MARK: - Computed: IntakeGoal
    var intakeGoal: IntakeGoal? {
        get {
            guard let data = intakeGoalData else { return nil }
            return try? JSONDecoder().decode(IntakeGoal.self, from: data)
        }
        set {
            intakeGoalData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Computed: Pills Per Day Left
    var pillsPerDayLeft: Double {
        // Only meaningful for prescription with refill dates
        guard medicationType == .prescription,
              let nextFill = nextFillDate else { return 0 }
        
        let currentDate = Date()
        let secondsInDay = 86400.0
        let daysLeft = nextFill.timeIntervalSince(currentDate) / secondsInDay
        guard daysLeft > 0 else { return 0 }
        let pillsLeft = totalMgRemaining / mgPerPill
        let pillsPerDay = pillsLeft / daysLeft
        return (pillsPerDay * 10).rounded() / 10
    }
    
    // MARK: - Computed: Days Until Refill
    var daysUntilRefill: Int {
        guard let nextFill = nextFillDate else { return 0 }
        let now = Date()
        let diff = Calendar.current.dateComponents([.day], from: now, to: nextFill).day ?? 0
        return max(diff, 0)
    }
    
    // MARK: - Computed: Pills Remaining
    var pillsRemaining: Double {
        guard mgPerPill > 0 else { return 0 }
        return totalMgRemaining / mgPerPill
    }
    
    // MARK: - Initializers
    
    /// Standard initializer for new medications
    init(
        name: String,
        desc: String? = nil,
        medicationType: MedicationType = .prescription,
        pillForm: String? = nil,
        lastFilledOn: Date? = nil,
        nextFillDate: Date? = nil,
        totalMgRemaining: Double,
        numberOfDaysSupply: Double? = nil,
        initialPillCount: Double,
        mgPerPill: Double,
        dailyDosage: Double? = nil,
        dailyDosageUnit: DosageUnit? = nil,
        intakeGoal: IntakeGoal? = nil,
        brandName: String? = nil,
        supplementType: String? = nil,
        servingSize: Int? = nil,
        servingsPerContainer: Int? = nil,
        purchaseLocation: String? = nil,
        expirationDate: Date? = nil,
        prescriberName: String? = nil,
        pharmacyName: String? = nil,
        rxNumber: String? = nil,
        refillsRemaining: Int? = nil
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.desc = desc
        self.medicationType = medicationType
        self.pillForm = pillForm
        self.lastFilledOn = lastFilledOn
        self.nextFillDate = nextFillDate
        self.totalMgRemaining = totalMgRemaining
        self.numberOfDaysSupply = numberOfDaysSupply
        self.initialPillCount = initialPillCount
        self.mgPerPill = mgPerPill
        self.dailyDosage = dailyDosage
        self.dailyDosageUnit = dailyDosageUnit
        self.intakeGoal = intakeGoal
        self.brandName = brandName
        self.supplementType = supplementType
        self.servingSize = servingSize
        self.servingsPerContainer = servingsPerContainer
        self.purchaseLocation = purchaseLocation
        self.expirationDate = expirationDate
        self.prescriberName = prescriberName
        self.pharmacyName = pharmacyName
        self.rxNumber = rxNumber
        self.refillsRemaining = refillsRemaining
        self.log = []
    }
}

@Model
final class MedLog {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    var mgIntake: Double = 0.0
    var totalMgRemaining: Double = 0.0
    var med: Med?
    
    init(mgIntake: Double, totalMgRemaining: Double) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.mgIntake = mgIntake
        self.totalMgRemaining = totalMgRemaining
    }
    
    var isRefill: Bool {
        return mgIntake > 0
    }
}
