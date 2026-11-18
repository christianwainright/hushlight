// swift-tools-version: 6.0
import PackageDescription

// Deliberately dependency-free: this package backs the contraction timer, which is
// outside the fitness suite's shared store and must not inherit its schema, its
// migrations, or its release lockstep (decision 0018). It shares the design system
// at the app layer, not data at this one.
let package = Package(
    name: "LaborKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "LaborKit", targets: ["LaborKit"])
    ],
    targets: [
        .target(
            name: "LaborKit",
            // HL-006: the module's own String Catalog. Everything LaborKit hands the
            // app/widgets as a plain `String` (Disclaimers, EarlyIrregular, CallSummary,
            // ProblemReport) is localized via `String(localized:bundle:.module,...)`, so
            // it needs its own catalog and its own `Bundle.module` rather than reaching
            // into the app's — LaborKit stays dependency-free and import-free of the app
            // (decision 0018), and that includes not assuming the app's bundle exists.
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LaborKitTests",
            dependencies: ["LaborKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
