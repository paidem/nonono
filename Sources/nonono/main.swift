import Foundation
import NonoCore

// nonono — plays "no no wait wait" while the lid is closing and Luigi's "phew"
// once it stops. Polls the hinge angle sensor; see NonoCore.ClosingDetector.

struct Options {
    var intervalSeconds = 0.05
    var quietSeconds = 0.5
    var minDrop = 2
    var closedBelow = 10
    var soundsDir = Options.defaultSoundsDir()
    var dryRun = false
    var verbose = false
    var testSounds = false

    /// Nearest `sounds/` directory above the binary (works from `.build/release`
    /// and from the arch-specific directory it links to), else `./sounds`.
    static func defaultSoundsDir() -> URL {
        var dir = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
            .deletingLastPathComponent()
        while dir.path != "/" {
            let candidate = dir.appendingPathComponent("sounds")
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("no-no-wait-wait.mp3").path) {
                return candidate
            }
            dir = dir.deletingLastPathComponent()
        }
        return URL(fileURLWithPath: "sounds")
    }

    static func parse() -> Options {
        var o = Options()
        var args = CommandLine.arguments.dropFirst().makeIterator()
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
            case "--sounds": o.soundsDir = URL(fileURLWithPath: value(a))
            case "--dry-run": o.dryRun = true
            case "--test-sounds": o.testSounds = true
            case "--verbose", "-v": o.verbose = true
            case "--help", "-h":
                print("""
                usage: nonono [options]
                  --interval S      poll period in seconds (default 0.05)
                  --quiet S         seconds without a further drop before "phew" (default 0.5)
                  --min-drop DEG    degrees below rest that count as closing (default 2)
                  --closed-below DEG  angles below this count as shut, no "phew" (default 10)
                  --sounds DIR      directory holding the two mp3 files
                  --dry-run         log events, play nothing
                  --test-sounds     play both clips once and exit
                  --verbose         log every angle change
                """)
                exit(0)
            default: fail("unknown argument \(a)")
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

let options = Options.parse()
setvbuf(stdout, nil, _IOLBF, 0)

let player: SoundPlayer?
if options.dryRun {
    player = nil
} else {
    do { player = try SoundPlayer(soundsDir: options.soundsDir) }
    catch { fail("cannot load sounds from \(options.soundsDir.path): \(error)") }
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
log("started, polling every \(options.intervalSeconds)s, quiet \(options.quietSeconds)s, sounds \(options.dryRun ? "off" : options.soundsDir.path)")

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
