import XCTest
@testable import NonoCore

final class ClosingDetectorTests: XCTestCase {
    private func detector() -> ClosingDetector {
        ClosingDetector(minDrop: 2, quietSeconds: 0.5, closedBelow: 10)
    }

    func testStillLidEmitsNothing() {
        var d = detector()
        for i in 0..<50 {
            XCTAssertNil(d.update(angle: 117, at: Double(i) * 0.05))
        }
    }

    func testOneDegreeJitterIsIgnored() {
        var d = detector()
        XCTAssertNil(d.update(angle: 117, at: 0))
        XCTAssertNil(d.update(angle: 116, at: 0.1))
        XCTAssertNil(d.update(angle: 117, at: 0.2))
        XCTAssertNil(d.update(angle: 116, at: 0.3))
    }

    func testDropOfMinDropStartsClosing() {
        var d = detector()
        XCTAssertNil(d.update(angle: 117, at: 0))
        XCTAssertEqual(d.update(angle: 115, at: 0.1), .closingStarted)
    }

    func testClosingStartedFiresOnce() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        XCTAssertEqual(d.update(angle: 115, at: 0.1), .closingStarted)
        XCTAssertNil(d.update(angle: 110, at: 0.2))
        XCTAssertNil(d.update(angle: 100, at: 0.3))
    }

    func testStopsAfterQuietPeriod() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        _ = d.update(angle: 110, at: 0.1)
        XCTAssertNil(d.update(angle: 110, at: 0.4))
        XCTAssertNil(d.update(angle: 110, at: 0.59))
        XCTAssertEqual(d.update(angle: 110, at: 0.6), .closingStopped)
        XCTAssertNil(d.update(angle: 110, at: 1.5))
    }

    func testEachFurtherDropRestartsQuietTimer() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        _ = d.update(angle: 110, at: 0.1)
        XCTAssertNil(d.update(angle: 109, at: 0.5))
        XCTAssertNil(d.update(angle: 109, at: 0.9))
        XCTAssertEqual(d.update(angle: 109, at: 1.0), .closingStopped)
    }

    func testReopeningAlsoCountsAsStopped() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        _ = d.update(angle: 100, at: 0.1)
        XCTAssertNil(d.update(angle: 105, at: 0.2))
        XCTAssertEqual(d.update(angle: 117, at: 0.7), .closingStopped)
    }

    func testFullCloseDoesNotReportStopped() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        XCTAssertEqual(d.update(angle: 60, at: 0.1), .closingStarted)
        _ = d.update(angle: 20, at: 0.2)
        _ = d.update(angle: 3, at: 0.3)
        XCTAssertEqual(d.update(angle: 3, at: 0.9), .closedFully)
    }

    func testClosingAgainAfterStopStartsAgain() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        _ = d.update(angle: 100, at: 0.1)
        XCTAssertEqual(d.update(angle: 100, at: 0.7), .closingStopped)
        XCTAssertEqual(d.update(angle: 97, at: 0.8), .closingStarted)
    }

    func testRestTracksOpeningWhileIdle() {
        var d = detector()
        _ = d.update(angle: 90, at: 0)
        _ = d.update(angle: 120, at: 0.1)
        XCTAssertNil(d.update(angle: 119, at: 0.2))
        XCTAssertEqual(d.update(angle: 118, at: 0.3), .closingStarted)
    }

    func testOpeningFromFullyClosedIsQuiet() {
        var d = detector()
        _ = d.update(angle: 117, at: 0)
        _ = d.update(angle: 0, at: 0.1)
        XCTAssertEqual(d.update(angle: 0, at: 0.7), .closedFully)
        XCTAssertNil(d.update(angle: 30, at: 1.0))
        XCTAssertNil(d.update(angle: 117, at: 1.5))
    }
}
