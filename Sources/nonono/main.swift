import AppKit

// nonono — menu bar app that plays "no no wait wait" while the lid is closing
// and Luigi's "phew" once it stops. See NonoCore.ClosingDetector for the logic.

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
