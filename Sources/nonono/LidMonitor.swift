import Foundation
import NonoCore
import os

/// Polls the hinge sensor and turns closing events into sounds. Start/stop
/// is what the menu bar "Enabled" toggle drives.
final class LidMonitor {
    private let sensor: LidAngleSensor
    private let player: SoundPlayer
    private var detector: ClosingDetector
    private var timer: Timer?
    let intervalSeconds: Double
    var mode: Mode = .nonono

    init?(defaults: UserDefaults = .standard) {
        guard let sensor = LidAngleSensor(), let player = try? SoundPlayer() else { return nil }
        self.sensor = sensor
        self.player = player
        // Tunable without a rebuild: defaults write com.pavel.nonono quietSeconds -float 1
        func number(_ key: String, _ fallback: Double) -> Double {
            defaults.object(forKey: key) == nil ? fallback : defaults.double(forKey: key)
        }
        intervalSeconds = number("intervalSeconds", 0.05)
        detector = ClosingDetector(minDrop: Int(number("minDrop", 2)),
                                   quietSeconds: number("quietSeconds", 0.5),
                                   closedBelow: Int(number("closedBelow", 10)))
    }

    var isRunning: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: intervalSeconds, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        log("monitoring started")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        log("monitoring stopped")
    }

    func testSounds() {
        switch mode {
        case .nonono:
            player.play(.wait)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [player] in player.play(.phew) }
        case .sadViolin:
            player.play(.violin)
        }
    }

    private func tick() {
        guard let angle = sensor.read() else { return }
        guard let event = detector.update(angle: angle, at: ProcessInfo.processInfo.systemUptime) else { return }
        let clip = clip(for: event, mode: mode)
        log("\(event) at \(angle) -> \(clip.map { "\($0)" } ?? "silence")")
        if let clip { player.play(clip) }
    }
}

private let logger = Logger(subsystem: "com.pavel.nonono", category: "lid")

/// Events go to the unified log; see them in Console.app or with
/// `log show --last 1h --predicate 'subsystem == "com.pavel.nonono"'`.
func log(_ msg: String) { logger.notice("\(msg, privacy: .public)") }
