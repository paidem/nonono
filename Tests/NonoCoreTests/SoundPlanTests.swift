import XCTest
@testable import NonoCore

final class SoundPlanTests: XCTestCase {
    func testNononoMode() {
        XCTAssertEqual(action(for: .closingStarted, mode: .nonono), .play(.wait))
        XCTAssertEqual(action(for: .closingStopped, mode: .nonono), .play(.phew))
        XCTAssertNil(action(for: .closedFully, mode: .nonono))
    }

    func testSadViolinPlaysOnStartAndStopsOnStop() {
        XCTAssertEqual(action(for: .closingStarted, mode: .sadViolin), .play(.violin))
        XCTAssertEqual(action(for: .closingStopped, mode: .sadViolin), .stop)
        XCTAssertEqual(action(for: .closedFully, mode: .sadViolin), .stop)
    }

    /// Close, stop, close again: violin, silence, violin again.
    func testSadViolinReplaysAfterAStop() {
        var d = ClosingDetector(minDrop: 2, quietSeconds: 0.5, closedBelow: 10)
        var actions: [SoundAction] = []
        let samples: [(Int, Double)] = [(117, 0), (100, 0.1), (100, 0.7), (100, 1.0), (90, 1.2), (90, 1.8)]
        for (angle, t) in samples {
            if let e = d.update(angle: angle, at: t), let a = action(for: e, mode: .sadViolin) { actions.append(a) }
        }
        XCTAssertEqual(actions, [.play(.violin), .stop, .play(.violin), .stop])
    }
}
