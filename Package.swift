// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "InfoSpace",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "InfoSpaceCore", targets: ["InfoSpaceCore"]),
        .library(name: "InfoSpaceUI", targets: ["InfoSpaceUI"]),
        .executable(name: "InfoSpace", targets: ["InfoSpaceApp"]),
    ],
    targets: [
        .target(name: "InfoSpaceCore"),
        .target(name: "InfoSpaceUI", dependencies: ["InfoSpaceCore"]),
        .executableTarget(
            name: "InfoSpaceApp", dependencies: ["InfoSpaceCore", "InfoSpaceUI"], path: "App",
            exclude: ["Info.plist"]),
        .target(name: "InfoSpaceExamples", dependencies: ["InfoSpaceCore", "InfoSpaceUI"], path: "Examples"),
        .testTarget(name: "InfoSpaceCoreTests", dependencies: ["InfoSpaceCore"]),
    ],
    swiftLanguageModes: [.v6]
)
