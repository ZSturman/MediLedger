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
    var id: String { self.rawValue }
}

enum MedicationType: String, CaseIterable, Identifiable {
    case prescription = "Prescription"
    case nonPrescription = "Non-Prescription"
    var id: String { self.rawValue }
}

// MARK: - Goal Tracking

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
    var targetDoses: Int              // Number of doses in the period
    var period: GoalPeriod            // Daily, weekly, or monthly
    var specificDays: Set<Weekday>?   // Optional: specific days for weekly goals
    var timesOfDay: [DateComponents]? // Optional: specific times (e.g., 8:00 AM, 8:00 PM)
    var startDate: Date?              // When this goal became active
    
    init(targetDoses: Int, period: GoalPeriod, specificDays: Set<Weekday>? = nil, timesOfDay: [DateComponents]? = nil, startDate: Date? = nil) {
        self.targetDoses = targetDoses
        self.period = period
        self.specificDays = specificDays
        self.timesOfDay = timesOfDay
        self.startDate = startDate
    }
}
