import AVFoundation
import XCTest
@testable import skatefit

final class PlaybackTests: XCTestCase {
    @MainActor
    func testRestartSeeksExistingLocalPlayerToBeginningAndResumes() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "replay-fixture", withExtension: "mp4"))
        let controller = ExercisePlaybackController(videoURL: url)
        let player = try XCTUnwrap(controller.player)
        let item = try XCTUnwrap(player.currentItem)
        let ready = expectation(for: NSPredicate { _, _ in item.status == .readyToPlay }, evaluatedWith: item)
        await fulfillment(of: [ready], timeout: 5)
        await player.seek(to: CMTime(seconds: 4, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        XCTAssertGreaterThan(player.currentTime().seconds, 3.9)
        let restarted = expectation(description: "Replay seek completed")
        controller.restart { finished in
            XCTAssertTrue(finished)
            restarted.fulfill()
        }
        await fulfillment(of: [restarted], timeout: 2)
        XCTAssertTrue(player.currentItem === item)
        XCTAssertLessThan(player.currentTime().seconds, 1)
        XCTAssertGreaterThan(player.rate, 0)
        player.pause()
    }

    @MainActor
    func testLongPressPresentsAtRecognitionBeforeReleaseAndOnlyOnce() {
        let coordinator = WorkoutVideoPlayerView.Coordinator()
        var presentations = 0
        coordinator.onLongPress = { presentations += 1 }
        coordinator.handleLongPressState(.possible)
        XCTAssertEqual(presentations, 0)
        coordinator.handleLongPressState(.began)
        XCTAssertEqual(presentations, 1, "The finger is still held when recognition begins")
        coordinator.handleLongPressState(.changed)
        coordinator.handleLongPressState(.ended)
        coordinator.handleLongPressState(.cancelled)
        XCTAssertEqual(presentations, 1)
    }
}
