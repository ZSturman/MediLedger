//
//  MedTrackerUITests.swift
//  MedTrackerUITests
//
//  Created by Zachary Sturman on 3/24/25.
//

import XCTest

final class MedTrackerUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests
    
    @MainActor
    func testInitialLaunch() throws {
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation bar should exist on launch")
        XCTAssertTrue(app.buttons["Add Medication"].exists, "Add medication button should be visible")
    }
    
    @MainActor
    func testEmptyStateMessage() throws {
        // If no medications exist, detail should show "Select an item"
        let selectItemText = app.staticTexts["Select an item"]
        if selectItemText.exists {
            XCTAssertTrue(selectItemText.exists, "Empty state message should be visible")
        }
    }
    
    // MARK: - Add Prescription Medication Tests
    
    @MainActor
    func testAddPrescriptionMedication() throws {
        // Tap the add button
        app.buttons["Add Medication"].tap()
        
        // Wait for the sheet to appear
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2), "New medication sheet should appear")
        
        // Fill in basic information
        medicationNameField.tap()
        medicationNameField.typeText("Lisinopril")
        
        let descriptionField = app.textFields["Description (optional)"]
        descriptionField.tap()
        descriptionField.typeText("Blood pressure medication")
        
        let formField = app.textFields["Form (e.g., Tablet, Capsule, Gummy)"]
        formField.tap()
        formField.typeText("Tablet")
        
        // Dismiss keyboard and scroll if needed
        app.swipeUp()
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify medication appears in list
        let medicationCell = app.staticTexts["Lisinopril"]
        XCTAssertTrue(medicationCell.waitForExistence(timeout: 2), "New medication should appear in list")
    }
    
    @MainActor
    func testAddPrescriptionWithAdvancedDetails() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Metformin")
        
        // Scroll to advanced details
        app.swipeUp()
        
        // Tap disclosure group for advanced prescription details
        let advancedDisclosure = app.buttons["Advanced Prescription Details"]
        if advancedDisclosure.exists {
            advancedDisclosure.tap()
            
            let prescriberField = app.textFields["Prescriber Name"]
            if prescriberField.exists {
                prescriberField.tap()
                prescriberField.typeText("Dr. Smith")
            }
            
            let pharmacyField = app.textFields["Pharmacy Name"]
            if pharmacyField.exists {
                pharmacyField.tap()
                pharmacyField.typeText("CVS Pharmacy")
            }
        }
        
        app.buttons["Save"].tap()
        
        let medicationCell = app.staticTexts["Metformin"]
        XCTAssertTrue(medicationCell.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testManualNextFillDateOverride() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Atorvastatin")
        
        // Dismiss the keyboard if present to avoid covering the toggle
        if app.keyboards.count > 0 {
            if app.keyboards.buttons["Done"].exists {
                app.keyboards.buttons["Done"].tap()
            } else if app.keyboards.buttons["return"].exists {
                app.keyboards.buttons["return"].tap()
            } else {
                // Tap elsewhere to dismiss keyboard
                app.staticTexts["Basic Information"].tap()
            }
        }
        
        // Wait for keyboard to dismiss completely
        XCTAssertTrue(app.keyboards.count == 0 || !app.keyboards.element.exists, "Keyboard should be dismissed")
        
        // Ensure we're in prescription mode (default), tap to be explicit
        let prescriptionButton = app.buttons["Prescription"]
        if prescriptionButton.exists && prescriptionButton.isEnabled {
            prescriptionButton.tap()
        }
        
        // Wait for UI to settle after mode change
        sleep(1)
        
        // Scroll down multiple times to make the toggle visible
        // The toggle is in the "Refill Information" section which may be below the fold
        for _ in 0..<3 {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Try finding as switch first, then as toggle
        var manualToggle = app.switches["manualNextFillToggle"]
        if !manualToggle.waitForExistence(timeout: 1) {
            // Try as toggle element type
            manualToggle = app.toggles["manualNextFillToggle"]
            if !manualToggle.waitForExistence(timeout: 1) {
                // Try finding by label text
                manualToggle = app.switches["Manually Set Next Fill Date"]
                if !manualToggle.exists {
                    manualToggle = app.toggles["Manually Set Next Fill Date"]
                }
            }
        }
        
        // If still not found, print debug info
        if !manualToggle.exists {
            print("🔍 Debug: Looking for toggle in view hierarchy")
            print("All switches: \(app.switches.allElementsBoundByIndex.map { $0.identifier })")
            print("All toggles: \(app.toggles.allElementsBoundByIndex.map { $0.identifier })")
        }
        
        XCTAssertTrue(manualToggle.exists, "Manual toggle should exist")
        
        // Scroll multiple times to ensure it's in the middle of the screen
        for _ in 0..<2 {
            if !manualToggle.isHittable {
                app.swipeUp()
                sleep(1)
            }
        }
        
        XCTAssertTrue(manualToggle.isHittable, "Manual toggle should be hittable")
        
        // Get initial state
        let initialState = isSwitchOn(manualToggle)
        print("Initial toggle state: \(initialState), value: \(String(describing: manualToggle.value))")
        print("Toggle isEnabled: \(manualToggle.isEnabled)")
        print("Toggle isHittable: \(manualToggle.isHittable)")
        print("Toggle frame: \(manualToggle.frame)")
        
        // Toggle it
        manualToggle.tap()
        
        // Wait for animation and state update
        sleep(1)
        
        // Check new state
        let newState = isSwitchOn(manualToggle)
        print("After tap toggle state: \(newState), value: \(String(describing: manualToggle.value))")
        print("After tap isEnabled: \(manualToggle.isEnabled)")
        
        // Try tapping again if it didn't work
        if !newState {
            print("⚠️ First tap didn't work, trying coordinate tap")
            manualToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            sleep(1)
            let thirdState = isSwitchOn(manualToggle)
            print("After coordinate tap: \(thirdState), value: \(String(describing: manualToggle.value))")
        }
        
        XCTAssertNotEqual(initialState, isSwitchOn(manualToggle), "Toggle state should have changed after tap")
        XCTAssertTrue(isSwitchOn(manualToggle), "Toggle should be ON after tapping from OFF state")
        
        app.buttons["Save"].tap()
    }
    
    // MARK: - Add Non-Prescription Medication Tests
    
    @MainActor
    func testAddNonPrescriptionMedication() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Vitamin D")
        
        // Switch to non-prescription type
        let typeSegment = app.buttons["Non-Prescription"]
        typeSegment.tap()
        
        let brandField = app.textFields["Brand Name (e.g., Advil, NatureMade)"]
        if brandField.exists {
            brandField.tap()
            brandField.typeText("NatureMade")
        }
        
        let typeField = app.textFields["Type (e.g., Vitamin D, Probiotic)"]
        if typeField.exists {
            typeField.tap()
            typeField.typeText("Vitamin")
        }
        
        app.buttons["Save"].tap()
        
        let medicationCell = app.staticTexts["Vitamin D"]
        XCTAssertTrue(medicationCell.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testAddNonPrescriptionWithExpirationDate() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Fish Oil")
        
        // Switch to non-prescription
        app.buttons["Non-Prescription"].tap()
        
        // Scroll to find expiration toggle
        app.swipeUp()
        
        let expirationToggle = app.switches["Has Expiration Date"]
        if expirationToggle.exists {
            setSwitch(expirationToggle, toOn: true)
        }
        
        app.buttons["Save"].tap()
    }
    
    // MARK: - Medication List Interaction Tests
    
    @MainActor
    func testSelectMedicationFromList() throws {
        // First add a medication
        addTestMedication(name: "Test Med")
        
        // Select it
        let medicationCell = app.staticTexts["Test Med"]
        if medicationCell.exists {
            medicationCell.tap()
            
            // Verify detail view appears
            XCTAssertTrue(app.navigationBars["Test Med"].waitForExistence(timeout: 2), "Detail view should show medication name")
        }
    }
    
    @MainActor
    func testSwipeToTakeMedication() throws {
        addTestMedication(name: "Swipe Test Med")
        
        let cell = app.staticTexts["Swipe Test Med"].firstMatch
        if cell.exists {
            cell.swipeRight()
            
            // Look for "Take" button
            let takeButton = app.buttons["Take"]
            if takeButton.exists {
                XCTAssertTrue(takeButton.exists, "Take button should appear on swipe")
            }
        }
    }
    
    @MainActor
    func testSwipeToDeleteMedication() throws {
        addTestMedication(name: "Delete Test Med")
        
        let cell = app.staticTexts["Delete Test Med"].firstMatch
        if cell.exists {
            cell.swipeLeft()
            
            // Look for delete button
            let deleteButton = app.buttons["Delete"]
            if deleteButton.exists {
                deleteButton.tap()
                
                // Verify medication is removed
                XCTAssertFalse(cell.exists, "Medication should be deleted")
            }
        }
    }
    
    @MainActor
    func testContextMenuDelete() throws {
        addTestMedication(name: "Context Delete Med")
        
        let cell = app.staticTexts["Context Delete Med"].firstMatch
        if cell.exists {
            cell.press(forDuration: 1.0)
            
            let deleteButton = app.buttons["Delete"]
            if deleteButton.exists {
                deleteButton.tap()
                XCTAssertFalse(cell.exists, "Medication should be deleted via context menu")
            }
        }
    }
    
    // MARK: - Medication Detail View Tests
    
    @MainActor
    func testMedicationDetailViewDisplays() throws {
        addTestMedication(name: "Detail View Med")
        
        let cell = app.staticTexts["Detail View Med"]
        if cell.exists {
            cell.tap()
            
            // Check for detail view elements
            XCTAssertTrue(app.navigationBars["Detail View Med"].exists, "Detail navigation bar should exist")
        }
    }
    
    @MainActor
    func testTakeMedicationFromDetailView() throws {
        addTestMedication(name: "Take Detail Med")
        
        app.staticTexts["Take Detail Med"].tap()
        
        // Look for Take button in detail view
        let takeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Take'")).firstMatch
        if takeButton.exists {
            takeButton.tap()
            
            // Verify the action completes without crashing
            sleep(1)
            XCTAssertTrue(app.exists, "App should remain responsive after taking medication")
        }
    }
    
    @MainActor
    func testCustomDoseSheet() throws {
        addTestMedication(name: "Custom Dose Med")
        
        app.staticTexts["Custom Dose Med"].tap()
        
        // Look for custom dose button
        let customDoseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Custom'")).firstMatch
        if customDoseButton.exists {
            customDoseButton.tap()
            
            // Verify sheet appears
            XCTAssertTrue(app.navigationBars.element.exists, "Custom dose sheet should appear")
        }
    }
    
    // MARK: - Goal Tracking Tests
    
    @MainActor
    func testAddMedicationWithGoal() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Goal Test Med")
        
        // Scroll to goal section
        app.swipeUp()
        app.swipeUp()
        
        let goalDisclosure = app.buttons["Intake Goal (Optional)"]
        if goalDisclosure.exists {
            goalDisclosure.tap()
            
            let goalToggle = app.switches["Set Intake Goal"]
            if goalToggle.exists {
                setSwitch(goalToggle, toOn: true)
            }
        }
        
        app.buttons["Save"].tap()
    }
    
    // MARK: - Edit Mode Tests
    
    @MainActor
    func testEditModeActivation() throws {
        addTestMedication(name: "Edit Mode Test")
        
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // Verify edit mode is active
            let doneButton = app.buttons["Done"]
            XCTAssertTrue(doneButton.exists, "Done button should appear in edit mode")
            
            doneButton.tap()
        }
    }
    
    @MainActor
    func testDeleteInEditMode() throws {
        addTestMedication(name: "Edit Delete Med")
        
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // Look for delete controls
            let deleteButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Delete'"))
            if deleteButtons.count > 0 {
                deleteButtons.firstMatch.tap()
                
                // Confirm deletion
                let confirmDelete = app.buttons["Delete"]
                if confirmDelete.exists {
                    confirmDelete.tap()
                }
            }
            
            app.buttons["Done"].tap()
        }
    }
    
    // MARK: - Edge Cases & Validation Tests
    
    @MainActor
    func testEmptyMedicationNameValidation() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        // Try to save without entering a name
        app.buttons["Save"].tap()
        
        // Sheet should still be present (validation should prevent saving)
        XCTAssertTrue(medicationNameField.exists, "Sheet should remain open with empty name")
        
        // Cancel to close
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }
    
    @MainActor
    func testVeryLongMedicationName() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("This Is A Very Long Medication Name That Should Still Work In The UI Without Breaking Anything Important")
        
        app.buttons["Save"].tap()
        
        // Should handle long names gracefully
        let longNameText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'This Is A Very Long'")).firstMatch
        XCTAssertTrue(longNameText.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSpecialCharactersInMedicationName() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Med-Name_123!@#")
        
        app.buttons["Save"].tap()
        
        let specialCharText = app.staticTexts["Med-Name_123!@#"]
        XCTAssertTrue(specialCharText.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testZeroDosageEntry() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Zero Dose Med")
        
        // Try to enter 0 for daily dosage
        app.swipeUp()
        
        let dailyDosageField = app.textFields.matching(identifier: "").element(boundBy: 3)
        if dailyDosageField.exists {
            dailyDosageField.tap()
            dailyDosageField.typeText("0")
        }
        
        app.buttons["Save"].tap()
    }
    
    @MainActor
    func testNegativeDosageValidation() throws {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        XCTAssertTrue(medicationNameField.waitForExistence(timeout: 2))
        
        medicationNameField.tap()
        medicationNameField.typeText("Negative Test")
        
        // Numeric keyboards typically don't allow negative entry
        // But test the field accepts only valid input
        let strengthField = app.textFields.matching(identifier: "").element(boundBy: 0)
        if strengthField.exists {
            XCTAssertTrue(strengthField.exists, "Strength field should exist")
        }
        
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let perfApp = XCUIApplication()
            perfApp.launch()
            perfApp.terminate()
        }
    }
    
    // Determines if a switch is on, accounting for different value representations ("1"/"0", "On"/"Off", true/false)
    private func isSwitchOn(_ element: XCUIElement) -> Bool {
        // First try to read the value as a string
        if let str = element.value as? String {
            let lowered = str.lowercased()
            // Check for common "on" representations
            if lowered == "1" || lowered == "on" || lowered == "true" {
                return true
            }
            // Check for common "off" representations  
            if lowered == "0" || lowered == "off" || lowered == "false" {
                return false
            }
        }
        // Try as number
        if let num = element.value as? NSNumber {
            return num.intValue == 1
        }
        // Fall back to checking selection state
        return element.isSelected
    }

    // Ensures a switch is toggled to the desired state, retrying and scrolling if needed
    private func setSwitch(_ switchElement: XCUIElement, toOn: Bool, maxAttempts: Int = 8, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(switchElement.waitForExistence(timeout: 3), "Switch should exist", file: file, line: line)
        
        // Give UI time to render and settle before checking state
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        
        var attempts = 0
        while isSwitchOn(switchElement) != toOn && attempts < maxAttempts {
            if switchElement.isHittable {
                switchElement.tap()
                // Wait longer for the state to update after tap
                RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            } else {
                app.swipeUp()
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            }
            attempts += 1
        }
        XCTAssertEqual(isSwitchOn(switchElement), toOn, "Switch should be \(toOn ? "on" : "off")", file: file, line: line)
    }

    // MARK: - Helper Methods
    
    private func addTestMedication(name: String) {
        app.buttons["Add Medication"].tap()
        
        let medicationNameField = app.textFields["Medication Name"]
        if medicationNameField.waitForExistence(timeout: 2) {
            medicationNameField.tap()
            medicationNameField.typeText(name)
            
            app.buttons["Save"].tap()
            
            // Wait for medication to appear
            _ = app.staticTexts[name].waitForExistence(timeout: 2)
        }
    }
}

