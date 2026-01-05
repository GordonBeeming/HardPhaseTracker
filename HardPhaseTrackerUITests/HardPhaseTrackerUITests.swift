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

        // Use longer timeouts for CI where simulators are slower
        let dashboard = app.buttons["Dashboard"]
        let log = app.buttons["Log"]
        let meals = app.buttons["Meals"]
        let analysis = app.buttons["Analysis"]

        XCTAssertTrue(dashboard.waitForExistence(timeout: 10), "Dashboard tab should exist")
        XCTAssertTrue(log.waitForExistence(timeout: 5), "Log tab should exist")
        XCTAssertTrue(meals.waitForExistence(timeout: 5), "Meals tab should exist")
        XCTAssertTrue(analysis.waitForExistence(timeout: 5), "Analysis tab should exist")

        log.tap()
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 10))

        meals.tap()
        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: 10))

        analysis.tap()
        XCTAssertTrue(app.navigationBars["Analysis"].waitForExistence(timeout: 10))

        dashboard.tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testCanCreateEditAndDeleteMealTemplate() throws {
        let app = XCUIApplication()
        app.launch()

        let mealsTab = app.buttons["Meals"]
        XCTAssertTrue(mealsTab.waitForExistence(timeout: 10), "Meals tab should exist")
        mealsTab.tap()
        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: 10))

        app.buttons["Add Meal"].tap()

        let nameField = app.textFields["mealEditor.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("UITest Meal")

        app.buttons["mealEditor.save"].tap()

        XCTAssertTrue(app.staticTexts["UITest Meal"].waitForExistence(timeout: 10))
        app.staticTexts["UITest Meal"].tap()

        XCTAssertTrue(app.buttons["mealDetail.edit"].waitForExistence(timeout: 10))
        app.buttons["mealDetail.edit"].tap()

        let editNameField = app.textFields["mealEditor.name"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 10))
        editNameField.tap()
        editNameField.press(forDuration: 1.0)
        editNameField.typeText(" Edited")

        app.buttons["mealEditor.save"].tap()
        XCTAssertTrue(app.navigationBars["UITest Meal Edited"].waitForExistence(timeout: 10))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["UITest Meal Edited"].waitForExistence(timeout: 10))

        let row = app.staticTexts["UITest Meal Edited"]
        row.swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["UITest Meal Edited"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDashboardShowsWeightCard() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for dashboard to be ready
        _ = app.navigationBars["Dashboard"].waitForExistence(timeout: 15)
        
        // Try different element types - VStack with accessibilityIdentifier can be queried different ways
        let weightCard = app.descendants(matching: .any).matching(identifier: "dashboard.weightTrend").firstMatch
        
        XCTAssertTrue(weightCard.waitForExistence(timeout: 15), "Weight card should be visible on dashboard")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
