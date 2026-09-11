# nonono

Background agent for MacBooks that plays "no no wait wait" the moment the lid
starts closing, and Luigi's "phew, mamma mia" once the closing stops.

- `Sources/NonoCore/ClosingDetector.swift` — pure state machine (unit tested).
- `Sources/nonono/` — hinge sensor read (IOKit HID 0x05AC:0x8104, usage 0x20/0x8A),
  AVAudioPlayer playback, 50 ms poll loop.
- `sounds/` — the two clips.

## Behaviour

Idle: track the resting angle (follows the lid when it opens further).
A drop of 2° or more from rest → play *wait*, enter *closing*.
Closing: every further drop restarts a 0.5 s timer. When the timer expires:
angle still ≥ 10° → play *phew*; angle < 10° → lid is shut, stay silent.
Starting a clip always cuts the other one off.

The sensor reports whole degrees at most every ~100 ms; a slow hand close can
pause 1–2 s between 1° steps, so a very slow close may trigger *phew* mid-close.
Raise `--quiet` if that annoys you.

## Use

    swift test                           # detector tests
    swift build -c release
    .build/release/nonono --dry-run -v   # log events, no audio
    .build/release/nonono --test-sounds  # play both clips once
    scripts/install.sh                   # launchd agent, starts at login, log in ~/Library/Logs/nonono.log
    scripts/uninstall.sh

Flags: `--quiet S` (0.5), `--min-drop DEG` (2), `--closed-below DEG` (10),
`--interval S` (0.05), `--sounds DIR`.
