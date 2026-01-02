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
    func testAppHasThreePrimaryTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let dashboard = app.buttons["Dashboard"]
        let meals = app.buttons["Meals"]
        let analysis = app.buttons["Analysis"]

        XCTAssertTrue(dashboard.waitForExistence(timeout: 2))
        XCTAssertTrue(meals.exists)
        XCTAssertTrue(analysis.exists)

        meals.tap()
        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: 2))

        analysis.tap()
        XCTAssertTrue(app.navigationBars["Analysis"].waitForExistence(timeout: 2))

        dashboard.tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
