# nonono

Menu bar app for MacBooks that plays "no no wait wait" the moment the lid
starts closing, and Luigi's "phew, mamma mia" once the closing stops.

## Install

    make install      # builds build/nonono.app, copies it to /Applications, launches it
    make uninstall

A laptop icon appears in the menu bar. Its menu has:

- **Enabled** — toggles the lid monitoring (remembered across launches).
- **Start at Login** — registers the app as a login item (System Settings ›
  General › Login Items). Requires the app to live in /Applications.
- **Test Sounds** — plays both clips.
- **Quit**

No permissions are needed. The HID manager matches only the lid sensor
interface, so it never opens a keyboard and never triggers Input Monitoring.
Both clips are embedded in the binary; the bundle has no external resources.

The app is ad-hoc signed. It runs fine locally; distributing it to other Macs
through a browser download would need Developer ID signing and notarization.

## Behaviour

Idle: track the resting angle (follows the lid when it opens further).
A drop of 2° or more from rest → play *wait*, enter *closing*.
Closing: every further drop restarts a 0.5 s timer. When the timer expires:
angle still ≥ 10° → play *phew*; angle < 10° → lid is shut, stay silent.
Starting a clip always cuts the other one off.

The sensor reports whole degrees at most every ~100 ms; a slow hand close can
pause 1–2 s between 1° steps, so a very slow close may trigger *phew* mid-close.

Tunables, read at launch from the app's defaults:

    defaults write com.pavel.nonono quietSeconds -float 1.0   # default 0.5
    defaults write com.pavel.nonono minDrop -int 1            # default 2
    defaults write com.pavel.nonono closedBelow -int 0        # default 10
    defaults write com.pavel.nonono intervalSeconds -float 0.1  # default 0.05

Events are in the unified log:

    log show --last 1h --predicate 'subsystem == "com.pavel.nonono"'

## Layout

- `Sources/NonoCore/ClosingDetector.swift` — pure state machine (unit tested, `swift test`).
- `Sources/CSounds/` — embeds `sounds/*.mp3` into the binary via `.incbin`.
- `Sources/nonono/` — hinge sensor read (IOKit HID 0x05AC:0x8104, usage 0x20/0x8A),
  AVAudioPlayer playback, poll loop, AppKit status item.
- `scripts/bundle.sh` — wraps the release binary in an ad-hoc signed `.app`.
