import Foundation

public enum ClosingEvent: Equatable {
    /// The lid started moving toward closed.
    case closingStarted
    /// The lid stopped closing (no further drop for `quietSeconds`) while still open.
    case closingStopped
    /// The lid stopped closing because it is now shut; nothing to be relieved about.
    case closedFully
}

/// Pure state machine that turns a stream of (angle, time) samples into closing
/// events. The sensor reports whole degrees, so `minDrop` of 2 filters the
/// occasional 1-degree wobble of a lid at rest.
public struct ClosingDetector {
    public let minDrop: Int
    public let quietSeconds: Double
    public let closedBelow: Int

    private enum State {
        case idle(rest: Int)
        case closing(low: Int, lastDrop: Double)
    }
    private var state: State?

    public init(minDrop: Int = 2, quietSeconds: Double = 0.5, closedBelow: Int = 10) {
        self.minDrop = minDrop
        self.quietSeconds = quietSeconds
        self.closedBelow = closedBelow
    }

    public var isClosing: Bool {
        if case .closing = state { return true }
        return false
    }

    public mutating func update(angle: Int, at time: Double) -> ClosingEvent? {
        switch state {
        case .none:
            state = .idle(rest: angle)
            return nil

        case .idle(let rest):
            if angle > rest {
                state = .idle(rest: angle)
            } else if angle <= rest - minDrop {
                state = .closing(low: angle, lastDrop: time)
                return .closingStarted
            }
            return nil

        case .closing(let low, let lastDrop):
            if angle < low {
                state = .closing(low: angle, lastDrop: time)
                return nil
            }
            if time - lastDrop >= quietSeconds {
                state = .idle(rest: angle)
                return low < closedBelow ? .closedFully : .closingStopped
            }
            return nil
        }
    }
}
