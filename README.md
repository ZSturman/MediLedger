# MediLedger

A **widget-first** iOS medication tracking app built with SwiftUI and WidgetKit. MediLedger helps you manage prescriptions and supplements with powerful home screen widgets for quick medication logging and at-a-glance tracking.

## Features

### 🎯 Widget-First Design
- **Interactive Home Screen Widgets**: Take medications, log half-doses, and refill prescriptions directly from your home screen
- **Customizable Widget Displays**: Choose from 15+ different data displays (pills remaining, daily average, streak tracking, etc.)
- **Real-Time Updates**: Widgets automatically update to reflect your latest medication intake

### 💊 Medication Management
- **Dual Medication Types**:
  - **Prescription**: Full refill tracking, days supply calculation, pharmacy information
  - **Non-Prescription**: Supplements, OTC medications, serving sizes, expiration dates
- **Flexible Dosing**: Log full doses, half doses, or custom amounts
- **Smart Tracking**: Automatic pill count updates, mg/dose tracking, and supply calculations

### 📊 Goal Tracking & Adherence
- **Intake Goals**: Set daily, weekly, or monthly adherence goals
- **Streak Tracking**: Monitor consecutive days of meeting your goals
- **Progress Monitoring**: Real-time progress bars and completion tracking
- **Specific Day Targeting**: Set goals for specific days of the week

### 📈 Analytics & Insights
- **7-Day Averages**: Track daily intake patterns over the past week
- **Refill Analytics**: Monitor average daily usage since last refill
- **Weekly Totals**: See cumulative intake for the current week
- **Historical Logs**: Complete medication history with timestamps

### 📤 Data Export
- **CSV Export**: Export medication logs for medical records or analysis
- **JSON Export**: Machine-readable format for data portability
- **Per-Medication or All**: Export individual medication logs or complete history

## Technical Stack

- **SwiftUI** & **SwiftData**: Modern Apple frameworks for UI and data persistence
- **WidgetKit**: Interactive home screen widgets with App Intents
- **AppIntents**: Deep integration for Siri shortcuts and widget actions
- **Swift 5.0**: Type-safe, modern Swift codebase

## Architecture

### Core Models
- `Med`: SwiftData model for medications with prescription/non-prescription support
- `MedLog`: Timestamped intake records with dosage tracking
- `MedEntity`: App Entity for widget integration and Siri support
- `IntakeGoal`: Goal tracking with period-based adherence

### Widget System
- `MedicationWidgetView`: Modular widget displays with 15+ configurable views
- `AppIntent`: Interactive widget actions (Take, TakeHalf, Refill)
- `MedTrackerWidget`: Widget timeline provider with real-time medication data

### Views
- `ContentView`: Master-detail medication list
- `MedicationDetailView`: Comprehensive medication information and actions
- `NewMedicationSheet`: Medication creation with progressive disclosure
- `MedicationGoalConfigView`: Goal setup and tracking

## Widget Display Options

The app supports **15+ customizable widget displays**:

### Universal Displays
- Pills Per Day Left
- Last Intake Time
- Total Pills Left
- Today's Total Intake
- 7-Day Average
- Pills Remaining
- This Week's Intake

### Goal-Based Displays
- Goal Progress (completed/target)
- Adherence Streak (consecutive days)
- Doses Left Today

### Prescription-Specific
- Average Since Refill
- Days Until Refill
- Refills Remaining

### Non-Prescription Specific
- Bottle Quantity Remaining

## Getting Started

### Requirements
- iOS 18.4+
- Xcode 16.0+
- Swift 5.0+

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/ZSturman/MediLedger.git
   ```

2. Open `MedTracker.xcodeproj` in Xcode

3. Build and run on your device or simulator

### Adding Your First Medication

1. Tap **"Add Medication"** button
2. Enter medication name and details
3. Choose **Prescription** or **Non-Prescription** type
4. Configure supply and dosage information
5. (Optional) Set an intake goal for adherence tracking
6. Tap **"Save"**

### Configuring Widgets

1. Long-press on your home screen
2. Tap the **+** button
3. Search for **"MediLedger"**
4. Add the small widget
5. Tap the widget to configure:
   - Select a medication
   - Choose primary display metric
   - Choose secondary display metric
6. Tap outside to save

### Taking Medications via Widget

- **Full Dose**: Tap the pill icon
- **Half Dose**: Tap the half-pill icon
- **Refill**: Use the refill action in the widget

## Project Structure

```
MedTracker/
├── MedTracker/                 # Main app target
│   ├── Models/                 # SwiftData models
│   │   ├── Medication.swift    # Core medication model
│   │   ├── MedEntity.swift     # App Entity for widgets
│   │   └── MedicationActions.swift # Medication business logic
│   ├── Views/                  # SwiftUI views
│   │   ├── MedicationDetailView.swift
│   │   ├── MedicationGoalConfigView.swift
│   │   └── MedicationActionButtons.swift
│   ├── Support/                # Helpers and utilities
│   │   ├── Enums.swift         # App enumerations
│   │   └── MedicationLogExporter.swift
│   ├── ContentView.swift       # Main list view
│   ├── NewMedicationSheet.swift # Add medication form
│   ├── Intents.swift           # App Intent implementations
│   └── SharedModel.swift       # Shared ModelContainer
│
├── MedTrackerWidget/           # Widget extension
│   ├── MedTrackerWidget.swift  # Widget definition
│   ├── MedicationWidgetView.swift # Widget UI components
│   ├── AppIntent.swift         # Widget configuration
│   └── MedTrackerWidgetBundle.swift
│
├── MedTrackerTests/            # Unit tests
└── MedTrackerUITests/          # UI tests
```

## Testing

The app includes comprehensive test coverage:

- **Unit Tests**: Medication logic, goal tracking, calculations
- **UI Tests**: Navigation, form validation, user interactions
- **Launch Tests**: Screenshots, orientation, accessibility

Run tests in Xcode: `⌘U`

## Data Persistence

- **SwiftData**: All medication data is stored locally using SwiftData
- **Shared Container**: Widget extension shares data with main app via shared model container
- **Privacy-First**: No cloud sync, all data stays on device

## Future Enhancements

- [ ] Scheduled dose reminders
- [ ] Multiple daily dose tracking
- [ ] Medication interaction warnings
- [ ] PDF prescription export
- [ ] Apple Watch companion app
- [ ] Medium/Large widget sizes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available under the MIT License.

## Acknowledgments

Built with SwiftUI, SwiftData, and WidgetKit on iOS 18.4+

---

**Note**: This is a personal health tracking tool. Always consult with healthcare professionals for medical advice.
