import XCTest
@testable import NonoCore

final class SoundPlanTests: XCTestCase {
    func testNononoMode() {
        XCTAssertEqual(clip(for: .closingStarted, mode: .nonono), .wait)
        XCTAssertEqual(clip(for: .closingStopped, mode: .nonono), .phew)
        XCTAssertNil(clip(for: .closedFully, mode: .nonono))
    }

    func testSadViolinPlaysOnlyOnStart() {
        XCTAssertEqual(clip(for: .closingStarted, mode: .sadViolin), .violin)
        XCTAssertNil(clip(for: .closingStopped, mode: .sadViolin))
        XCTAssertNil(clip(for: .closedFully, mode: .sadViolin))
    }

    /// Close, stop, close again: the violin plays once per episode.
    func testSadViolinReplaysAfterAStop() {
        var d = ClosingDetector(minDrop: 2, quietSeconds: 0.5, closedBelow: 10)
        var clips: [Clip] = []
        let samples: [(Int, Double)] = [(117, 0), (100, 0.1), (100, 0.7), (100, 1.0), (90, 1.2), (90, 1.8)]
        for (angle, t) in samples {
            if let e = d.update(angle: angle, at: t), let c = clip(for: e, mode: .sadViolin) { clips.append(c) }
        }
        XCTAssertEqual(clips, [.violin, .violin])
    }
}
