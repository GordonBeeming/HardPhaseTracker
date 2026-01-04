//
//  HardPhaseTrackerUITests.swift
//  HardPhaseTrackerUITests
//
//  Created by Gordon Beeming on 2/1/2026.
//

import XCTest

final class HardPhaseTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppHasFourPrimaryTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let dashboard = app.buttons["Dashboard"]
        let log = app.buttons["Log"]
        let meals = app.buttons["Meals"]
        let analysis = app.buttons["Analysis"]

        XCTAssertTrue(dashboard.waitForExistence(timeout: 2))
        XCTAssertTrue(log.exists)
        XCTAssertTrue(meals.exists)
        XCTAssertTrue(analysis.exists)

        log.tap()
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 2))

        meals.tap()
        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: 2))

        analysis.tap()
        XCTAssertTrue(app.navigationBars["Analysis"].waitForExistence(timeout: 2))

        dashboard.tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCanCreateEditAndDeleteMealTemplate() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Meals"].tap()
        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: 2))

        app.buttons["Add Meal"].tap()

        let nameField = app.textFields["mealEditor.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UITest Meal")

        app.buttons["mealEditor.save"].tap()

        XCTAssertTrue(app.staticTexts["UITest Meal"].waitForExistence(timeout: 2))
        app.staticTexts["UITest Meal"].tap()

        XCTAssertTrue(app.buttons["mealDetail.edit"].waitForExistence(timeout: 2))
        app.buttons["mealDetail.edit"].tap()

        let editNameField = app.textFields["mealEditor.name"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 2))
        editNameField.tap()
        editNameField.press(forDuration: 1.0)
        editNameField.typeText(" Edited")

        app.buttons["mealEditor.save"].tap()
        XCTAssertTrue(app.navigationBars["UITest Meal Edited"].waitForExistence(timeout: 2))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["UITest Meal Edited"].waitForExistence(timeout: 2))

        let row = app.staticTexts["UITest Meal Edited"]
        row.swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["UITest Meal Edited"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testDashboardShowsWeightCard() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for dashboard to be ready
        _ = app.navigationBars["Dashboard"].waitForExistence(timeout: 5)
        
        // The weight card should render (it's not conditional)
        // It might be below the viewport, so scroll to find it
        let weightCard = app.otherElements["dashboard.weightTrend"]
        
        // First check if it's immediately visible
        if weightCard.waitForExistence(timeout: 2) {
            XCTAssertTrue(true)
            return
        }
        
        // If not visible, scroll down to find it
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Scroll down multiple times with delays to ensure content loads
            for attempt in 0..<5 {
                scrollView.swipeUp()
                sleep(UInt32(1))
                if weightCard.exists {
                    XCTAssertTrue(true)
                    return
                }
            }
        }
        
        XCTFail("Weight card should be visible on dashboard after scrolling")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
