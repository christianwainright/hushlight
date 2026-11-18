// swift-tools-version: 6.0
import PackageDescription

// The QA instrument for the contraction timer (decision 0021). **Nothing here ever
// ships**: no app target links LaborSim, and it depends on LaborKit rather than the
// other way round, so the arrow of dependency cannot be reversed by accident.
//
// `LaborOracle`'s empty dependency list is not an oversight — it is the enforcement
// of decision 0021's independence rule. The oracle is the referee in a differential
// test, and a referee that shares code with a player referees nothing. If it ever
// gains a dependency on LaborKit, every agreement it reports becomes vacuous.
let package = Package(
    name: "LaborSim",
    platforms: [.iOS(.v18)],
    // One product on purpose. `LaborOracle` is a target and deliberately *not* a
    // library anyone can link: it is the referee for this package's differential
    // test and has no business outside it. Keeping the product list to one also
    // keeps this package's generated scheme shaped like every other package's, so
    // `scripts/test.sh`'s uniform `-scheme <package>` invocation reaches the tests
    // — a multi-product package generates per-product schemes that carry no test
    // action, and the suite would fail on invocation rather than on a real defect.
    products: [
        .library(name: "LaborSim", targets: ["LaborSim"])
    ],
    dependencies: [
        // Path-based, never remote: sibling packages resolve on disk, and CI
        // fails any manifest that names a remote source. (Do not write that token
        // here even in a comment — the check is a plain grep over this file.)
        .package(path: "../LaborKit")
    ],
    targets: [
        .target(
            name: "LaborSim",
            dependencies: [.product(name: "LaborKit", package: "LaborKit")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "LaborOracle",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LaborSimTests",
            dependencies: [
                "LaborSim",
                "LaborOracle",
                .product(name: "LaborKit", package: "LaborKit")
            ],
            resources: [.copy("Fixtures")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
