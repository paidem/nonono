// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "nonono",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "NonoCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "CSounds",
            cSettings: [.headerSearchPath("../../sounds")]
        ),
        .executableTarget(
            name: "nonono",
            dependencies: ["NonoCore", "CSounds"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "NonoCoreTests",
            dependencies: ["NonoCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
