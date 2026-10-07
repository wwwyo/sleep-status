// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SleepStatus",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "SleepStatus", targets: ["SleepStatus"])],
    targets: [.executableTarget(name: "SleepStatus")],
    swiftLanguageVersions: [.v5]
)
