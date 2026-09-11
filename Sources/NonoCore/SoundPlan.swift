import Foundation

public enum Mode: String, CaseIterable {
    /// "no no wait wait" while closing, "phew" once it stops.
    case nonono
    /// Sad violin once per closing episode, nothing when it stops.
    case sadViolin
}

public enum Clip: Equatable {
    case wait, phew, violin
}

/// Which clip, if any, a closing event should trigger in the given mode.
/// Every closing episode starts a clip from the beginning; a stop is only
/// acknowledged in nonono mode.
public func clip(for event: ClosingEvent, mode: Mode) -> Clip? {
    switch (mode, event) {
    case (.nonono, .closingStarted): return .wait
    case (.nonono, .closingStopped): return .phew
    case (.nonono, .closedFully): return nil
    case (.sadViolin, .closingStarted): return .violin
    case (.sadViolin, .closingStopped), (.sadViolin, .closedFully): return nil
    }
}
