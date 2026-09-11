import Foundation
import NonoCore

// nonono — plays "no no wait wait" while the lid is closing and Luigi's "phew"
// once it stops. Polls the hinge angle sensor; see NonoCore.ClosingDetector.

struct Options {
    var intervalSeconds = 0.05
    var quietSeconds = 0.5
    var minDrop = 2
    var closedBelow = 10
    var dryRun = false
    var verbose = false
    var testSounds = false

    static let usage = """
        usage: nonono [options]            run in the foreground
               nonono install [options]    copy to ~/.local/bin and start at login via launchd
               nonono uninstall            stop and remove the launchd agent
        options:
          --interval S        poll period in seconds (default 0.05)
          --quiet S           seconds without a further drop before "phew" (default 0.5)
          --min-drop DEG      degrees below rest that count as closing (default 2)
          --closed-below DEG  angles below this count as shut, no "phew" (default 10)
          --dry-run           log events, play nothing
          --verbose, -v       log every angle change
          --test-sounds       play both clips once and exit
        """

    static func parse(_ arguments: [String]) -> Options {
        var o = Options()
        var args = arguments.makeIterator()
        func value(_ flag: String) -> String {
            guard let v = args.next() else { fail("\(flag) needs a value") }
            return v
        }
        func double(_ flag: String) -> Double {
            guard let v = Double(value(flag)) else { fail("\(flag) needs a number") }
            return v
        }
        func int(_ flag: String) -> Int {
            guard let v = Int(value(flag)) else { fail("\(flag) needs an integer") }
            return v
        }
        while let a = args.next() {
            switch a {
            case "--interval": o.intervalSeconds = double(a)
            case "--quiet": o.quietSeconds = double(a)
            case "--min-drop": o.minDrop = int(a)
            case "--closed-below": o.closedBelow = int(a)
            case "--dry-run": o.dryRun = true
            case "--test-sounds": o.testSounds = true
            case "--verbose", "-v": o.verbose = true
            case "--help", "-h": print(usage); exit(0)
            default: fail("unknown argument \(a)\n\(usage)")
            }
        }
        return o
    }
}

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data("nonono: \(msg)\n".utf8))
    exit(2)
}

func log(_ msg: String) {
    let stamp = ISO8601DateFormatter().string(from: Date())
    print("\(stamp) \(msg)")
    fflush(stdout)
}

setvbuf(stdout, nil, _IOLBF, 0)
var arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first {
case "install":
    let daemonArgs = Array(arguments.dropFirst())
    _ = Options.parse(daemonArgs)   // validate before writing them into the plist
    do { try Installer.install(daemonArgs: daemonArgs) } catch { fail("install: \(error)") }
    exit(0)
case "uninstall":
    do { try Installer.uninstall() } catch { fail("uninstall: \(error)") }
    exit(0)
default:
    break
}

let options = Options.parse(arguments)

let player: SoundPlayer?
if options.dryRun {
    player = nil
} else {
    do { player = try SoundPlayer() }
    catch { fail("cannot decode embedded sounds: \(error)") }
}

if options.testSounds {
    guard let player else { fail("--test-sounds and --dry-run do not mix") }
    log("playing no-no-wait-wait")
    player.playWait()
    Thread.sleep(forTimeInterval: 2)
    log("playing phew (cuts the first one off)")
    player.playPhew()
    Thread.sleep(forTimeInterval: 3)
    exit(0)
}

guard let sensor = LidAngleSensor() else { fail("no lid angle sensor found on this Mac") }

var detector = ClosingDetector(minDrop: options.minDrop,
                               quietSeconds: options.quietSeconds,
                               closedBelow: options.closedBelow)
var lastLogged: Int?
log("started, polling every \(options.intervalSeconds)s, quiet \(options.quietSeconds)s, sounds \(options.dryRun ? "off" : "on")")

signal(SIGTERM) { _ in exit(0) }
signal(SIGINT) { _ in exit(0) }

let timer = Timer(timeInterval: options.intervalSeconds, repeats: true) { _ in
    guard let angle = sensor.read() else { return }
    if options.verbose, angle != lastLogged {
        log("angle \(angle)")
        lastLogged = angle
    }
    let now = ProcessInfo.processInfo.systemUptime
    switch detector.update(angle: angle, at: now) {
    case .closingStarted:
        log("closing at \(angle) -> no no wait wait")
        player?.playWait()
    case .closingStopped:
        log("stopped at \(angle) -> phew")
        player?.playPhew()
    case .closedFully:
        log("shut at \(angle)")
    case nil:
        break
    }
}
RunLoop.main.add(timer, forMode: .common)
RunLoop.main.run()
