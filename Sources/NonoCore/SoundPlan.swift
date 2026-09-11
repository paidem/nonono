import Foundation

public enum Mode: String, CaseIterable {
    /// "no no wait wait" while closing, "phew" once it stops.
    case nonono
    /// Sad violin while closing, cut off as soon as the closing stops.
    case sadViolin
}

public enum Clip: Equatable {
    case wait, phew, violin
}

public enum SoundAction: Equatable {
    case play(Clip)
    case stop
}

/// What a closing event should do to playback in the given mode.
/// Every closing episode starts its clip from the beginning.
public func action(for event: ClosingEvent, mode: Mode) -> SoundAction? {
    switch (mode, event) {
    case (.nonono, .closingStarted): return .play(.wait)
    case (.nonono, .closingStopped): return .play(.phew)
    case (.nonono, .closedFully): return nil
    case (.sadViolin, .closingStarted): return .play(.violin)
    case (.sadViolin, .closingStopped), (.sadViolin, .closedFully): return .stop
    }
}
