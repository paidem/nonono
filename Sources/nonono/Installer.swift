import Foundation

/// Installs the running executable as a per-user launchd agent: copies it to
/// ~/.local/bin, writes the plist with any extra daemon flags, and bootstraps it.
enum Installer {
    static let label = "com.pavel.nonono"
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let plist = home.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    static let installedBinary = home.appendingPathComponent(".local/bin/nonono")
    static let logFile = home.appendingPathComponent("Library/Logs/nonono.log")
    static var domain: String { "gui/\(getuid())" }

    static func install(daemonArgs: [String]) throws {
        let fm = FileManager.default
        let source = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        if source != installedBinary.resolvingSymlinksInPath() {
            try fm.createDirectory(at: installedBinary.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: installedBinary.path) { try fm.removeItem(at: installedBinary) }
            try fm.copyItem(at: source, to: installedBinary)
        }
        try fm.createDirectory(at: plist.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.createDirectory(at: logFile.deletingLastPathComponent(), withIntermediateDirectories: true)

        let dict: [String: Any] = [
            "Label": label,
            "ProgramArguments": [installedBinary.path] + daemonArgs,
            "RunAtLoad": true,
            "KeepAlive": true,
            "ProcessType": "Interactive",
            "StandardOutPath": logFile.path,
            "StandardErrorPath": logFile.path,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try data.write(to: plist)

        _ = launchctl("bootout", "\(domain)/\(label)")
        // bootout returns before the old job is gone; a bootstrap right after fails with EIO.
        var ok = false
        for _ in 0..<20 {
            if launchctl("bootstrap", domain, plist.path) == 0 { ok = true; break }
            Thread.sleep(forTimeInterval: 0.5)
        }
        guard ok else { throw InstallError("launchctl bootstrap failed") }
        print("installed \(label)\n  binary  \(installedBinary.path)\n  plist   \(plist.path)\n  log     \(logFile.path)")
    }

    static func uninstall() throws {
        _ = launchctl("bootout", "\(domain)/\(label)")
        let fm = FileManager.default
        if fm.fileExists(atPath: plist.path) { try fm.removeItem(at: plist) }
        if fm.fileExists(atPath: installedBinary.path) { try fm.removeItem(at: installedBinary) }
        print("removed \(label)")
    }

    @discardableResult
    private static func launchctl(_ args: String...) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return -1 }
        p.waitUntilExit()
        return p.terminationStatus
    }

    struct InstallError: Error, CustomStringConvertible {
        let description: String
        init(_ d: String) { description = d }
    }
}
