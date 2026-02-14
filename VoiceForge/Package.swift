// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VoiceForge",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VoiceForge",
            targets: ["VoiceForge"]
        )
    ],
    dependencies: [
        // Keyboard Shortcuts
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0"),
        
        // Sparkle for auto-updates
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0")
    ],
    targets: [
        .target(
            name: "VoiceForge",
            dependencies: [
                "KeyboardShortcuts",
                "Sparkle"
            ],
            path: "VoiceForge"
        ),
        .testTarget(
            name: "VoiceForgeTests",
            dependencies: ["VoiceForge"],
            path: "VoiceForgeTests"
        )
    ]
)
