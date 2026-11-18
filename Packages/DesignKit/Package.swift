// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"])
    ],
    targets: [
        .target(
            name: "DesignKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DesignKitTests",
            dependencies: ["DesignKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
