//
//  skatefitUITests.swift
//  skatefitUITests
//
//  Created by Mike Shaffer on 4/23/25.
//

import XCTest

final class skatefitUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testExerciseLongPressShowsDetailsAndHorizontalSwipeStillPages() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestExercisePlayer")
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "replay-fixture", withExtension: "mp4"))
        app.launchEnvironment["UITEST_VIDEO_BASE64"] = try Data(contentsOf: fixture).base64EncodedString()
        app.launch()

        let firstTitle = app.staticTexts["exercise-title-0"]
        XCTAssertTrue(firstTitle.waitForExistence(timeout: 5))

        let replay = app.buttons["replay-video-button"]
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()
        XCTAssertTrue(firstTitle.exists)
        XCTAssertFalse(app.buttons["30 seconds"].exists)
        let playerCapture = XCTAttachment(screenshot: app.screenshot())
        playerCapture.name = "Synthetic player and informational target"
        playerCapture.lifetime = .keepAlways
        add(playerCapture)

        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.7)

        let details = app.scrollViews["exercise-details-overlay"]
        XCTAssertTrue(details.waitForExistence(timeout: 2))

        XCTAssertTrue(app.staticTexts["Overview"].exists)
        XCTAssertTrue(app.staticTexts["Detailed Guide"].exists)
        XCTAssertTrue(app.staticTexts["First detail sentence."].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Formatted exercise guide"
        attachment.lifetime = .keepAlways
        add(attachment)

        let closeButton = app.buttons["Close exercise details"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        closeButton.tap()
        XCTAssertTrue(details.waitForNonExistence(timeout: 2))

        app.swipeLeft()

        let secondTitle = app.staticTexts["exercise-title-1"]
        XCTAssertTrue(secondTitle.waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let app = XCUIApplication()
                app.launchArguments.append("-UITestExercisePlayer")
                app.launch()
            }
        }
    }
}
