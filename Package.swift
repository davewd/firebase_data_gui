// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FirebaseDataGUI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "FirebaseDataGUI",
            targets: ["FirebaseDataGUI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FirebaseDataGUI",
            dependencies: [],
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
