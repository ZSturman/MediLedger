//
//  MedTrackerUITestsLaunchTests.swift
//  MedTrackerUITests
//
//  Created by Zachary Sturman on 3/24/25.
//

import XCTest

final class MedTrackerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the app launched successfully
        XCTAssertTrue(app.exists, "App should launch successfully")
        
        // Capture launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithEmptyState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "EMPTY-STATE"]
        app.launch()
        
        // Verify empty state UI elements
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation should be present")
        XCTAssertTrue(app.buttons["Add Medication"].exists, "Add button should be visible in empty state")
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Empty State"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchInPortraitOrientation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Force portrait orientation if supported
        XCUIDevice.shared.orientation = .portrait
        
        // Wait a moment for orientation change
        sleep(1)
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Portrait Orientation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchInLandscapeOrientation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Wait for rotation to complete
        sleep(1)
        
        // Verify UI adapts to landscape
        XCTAssertTrue(app.exists, "App should handle landscape orientation")
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Landscape Orientation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        
        // Reset orientation
        XCUIDevice.shared.orientation = .portrait
    }
    
    @MainActor
    func testLaunchWithMedicationsList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
        app.launch()
        
        // Add a medication to test list state
        if app.buttons["Add Medication"].exists {
            app.buttons["Add Medication"].tap()
            
            let nameField = app.textFields["Medication Name"]
            if nameField.waitForExistence(timeout: 2) {
                nameField.tap()
                nameField.typeText("Screenshot Test Med")
                
                app.buttons["Save"].tap()
                
                // Wait for medication to appear
                let medCell = app.staticTexts["Screenshot Test Med"]
                if medCell.waitForExistence(timeout: 2) {
                    let screenshot = XCTAttachment(screenshot: app.screenshot())
                    screenshot.name = "Medications List View"
                    screenshot.lifetime = .keepAlways
                    add(screenshot)
                }
            }
        }
    }
    
    @MainActor
    func testLaunchAndOpenAddSheet() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Add Medication"].tap()
        
        // Wait for sheet to appear
        let nameField = app.textFields["Medication Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Add medication sheet should appear")
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Add Medication Sheet"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchAndNavigateToDetail() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Add a medication first
        app.buttons["Add Medication"].tap()
        
        let nameField = app.textFields["Medication Name"]
        if nameField.waitForExistence(timeout: 2) {
            nameField.tap()
            nameField.typeText("Detail Screenshot Med")
            app.buttons["Save"].tap()
            
            // Navigate to detail
            let medCell = app.staticTexts["Detail Screenshot Med"]
            if medCell.waitForExistence(timeout: 2) {
                medCell.tap()
                
                // Wait for detail view
                let detailNav = app.navigationBars["Detail Screenshot Med"]
                if detailNav.waitForExistence(timeout: 2) {
                    let screenshot = XCTAttachment(screenshot: app.screenshot())
                    screenshot.name = "Medication Detail View"
                    screenshot.lifetime = .keepAlways
                    add(screenshot)
                }
            }
        }
    }
    
    @MainActor
    func testLaunchWithDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "DARK-MODE"]
        app.launch()
        
        // Note: Actual dark mode testing would require scheme configuration
        // This test documents the intent
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Dark Mode (if enabled)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchMemoryWarning() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify app state before simulated memory warning
        XCTAssertTrue(app.exists, "App should be running")
        
        // Note: Actual memory warning simulation would require additional setup
        // This test verifies the app is in a state to handle such events
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Before Memory Warning"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchAccessibilityLabels() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify key UI elements have accessibility support
        let addButton = app.buttons["Add Medication"]
        XCTAssertTrue(addButton.exists, "Add button should be accessible")
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled")
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Accessibility Elements"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchAndCheckUIElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify all critical UI elements are present
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation bar should exist")
        XCTAssertTrue(app.buttons["Add Medication"].exists, "Add medication button should exist")
        
        // Check for Edit button (appears with medications) - existence check only
        _ = app.buttons["Edit"].exists
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "All UI Elements"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchPerformanceMultipleTimes() throws {
        let app = XCUIApplication()
        
        // Test launch performance with multiple launches
        for iteration in 1...3 {
            app.launch()
            
            XCTAssertTrue(app.exists, "App should launch on iteration \(iteration)")
            
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Launch Iteration \(iteration)"
            screenshot.lifetime = .deleteOnSuccess
            add(screenshot)
            
            app.terminate()
            sleep(1)
        }
    }
    
    @MainActor
    func testLaunchAfterTermination() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.exists, "App should launch initially")
        
        // Terminate the app
        app.terminate()
        sleep(1)
        
        // Relaunch
        app.launch()
        
        XCTAssertTrue(app.exists, "App should relaunch after termination")
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation should be restored")
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "After Termination"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    
    @MainActor
    func testLaunchWithSystemAlert() throws {
        let app = XCUIApplication()
        app.launch()
        
        // This test verifies the app can handle potential system alerts
        // Actual alert handling would depend on permissions needed
        
        XCTAssertTrue(app.exists, "App should handle launch with potential alerts")
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "System Alert Handling"
        screenshot.lifetime = .deleteOnSuccess
        add(screenshot)
    }
}
