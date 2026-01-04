//
//  Enums.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/27/25.
//

import Foundation


enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case week = "Week"
    case month = "Month"
}

// Define enums to represent dosage units and medication type.
enum DosageUnit: String, CaseIterable, Identifiable {
    case mg = "mg"
    case pill = "Pill"
    case ml = "mL"
    case spray = "Spray"
    case drop = "Drop"
    case puff = "Puff"
    case application = "Application"
    var id: String { self.rawValue }
}

enum MedicationType: String, CaseIterable, Identifiable {
    case prescription = "Prescription"
    case nonPrescription = "Non-Prescription"
    var id: String { self.rawValue }
}

enum MedicationForm: String, CaseIterable, Identifiable, Codable {
    case tablet = "Tablet"
    case capsule = "Capsule"
    case gummy = "Gummy"
    case softgel = "Softgel"
    case liquid = "Liquid"
    case syrup = "Syrup"
    case suspension = "Suspension"
    case cream = "Cream"
    case ointment = "Ointment"
    case gel = "Gel"
    case lotion = "Lotion"
    case patch = "Patch"
    case injection = "Injection"
    case inhaler = "Inhaler"
    case nasalSpray = "Nasal Spray"
    case eyeDrops = "Eye Drops"
    case earDrops = "Ear Drops"
    case powder = "Powder"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    /// SF Symbol name for this medication form
    var sfSymbolName: String {
        switch self {
        case .tablet:
            return "pill.fill"
        case .capsule, .softgel:
            return "capsule.fill"
        case .gummy:
            return "pills.fill"
        case .liquid, .syrup, .suspension:
            return "drop.fill"
        case .cream, .ointment, .gel, .lotion:
            return "cross.vial.fill"
        case .patch:
            return "bandage.fill"
        case .injection:
            return "syringe.fill"
        case .inhaler:
            return "lungs.fill"
        case .nasalSpray:
            return "nose.fill"
        case .eyeDrops:
            return "eye.fill"
        case .earDrops:
            return "ear.fill"
        case .powder:
            return "allergens.fill"
        case .other:
            return "pills.fill"
        }
    }
    
    /// SF Symbol name for half dose of this medication form
    var sfSymbolNameHalf: String {
        switch self {
        case .tablet:
            return "pill.circle"
        case .capsule, .softgel:
            return "capsule.righthalf.filled"
        case .liquid, .syrup, .suspension:
            return "drop.halffull"
        default:
            return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Goal Tracking

enum GoalConstraintType: String, CaseIterable, Codable, Identifiable {
    case atLeast = "At Least"
    case noMoreThan = "No More Than"
    case both = "Between"
    
    var id: String { self.rawValue }
}

enum GoalPeriod: String, CaseIterable, Codable, Identifiable {
    case perDay = "Per Day"
    case perWeek = "Per Week"
    case perMonth = "Per Month"
    
    var id: String { self.rawValue }
}

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    
    var id: Int { self.rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

struct IntakeGoal: Codable, Equatable {
    var targetDoses: Double            // Minimum number of doses in the period (for atLeast/both)
    var maximumDoses: Double?          // Maximum number of doses in the period (for noMoreThan/both)
    var constraintType: GoalConstraintType // Type of constraint
    var period: GoalPeriod             // Daily, weekly, or monthly
    var specificDays: Set<Weekday>?    // Optional: specific days for weekly goals
    var timesOfDay: [DateComponents]?  // Optional: specific times (e.g., 8:00 AM, 8:00 PM)
    var startDate: Date?               // When this goal became active
    
    init(targetDoses: Double, maximumDoses: Double? = nil, constraintType: GoalConstraintType = .atLeast, period: GoalPeriod, specificDays: Set<Weekday>? = nil, timesOfDay: [DateComponents]? = nil, startDate: Date? = nil) {
        self.targetDoses = targetDoses
        self.maximumDoses = maximumDoses
        self.constraintType = constraintType
        self.period = period
        self.specificDays = specificDays
        self.timesOfDay = timesOfDay
        self.startDate = startDate
    }
}
