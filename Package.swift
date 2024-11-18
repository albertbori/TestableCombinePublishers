// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestableCombinePublishers",
    platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TestableCombinePublishers",
            targets: ["TestableCombinePublishers"]
        ),
        .library(
            name: "SwiftTestingTestableCombinePublishers",
            targets: ["SwiftTestingTestableCombinePublishers"]
        ),
        .library(
            name: "TestableCombinePublishersUtility",
            targets: ["TestableCombinePublishersUtility"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TestableCombinePublishers",
            dependencies: ["TestableCombinePublishersUtility"],
            path: "Sources/TestableCombinePublishers",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [
                .linkedFramework("XCTest")
            ]),
        .target(
            name: "SwiftTestingTestableCombinePublishers",
            dependencies: ["TestableCombinePublishersUtility"],
            path: "Sources/SwiftTestingTestableCombinePublishers",
            linkerSettings: [
                .linkedFramework("Testing")
            ]
        ),
        .target(
            name: "TestableCombinePublishersUtility",
            dependencies: [],
            path: "Sources/TestableCombinePublishersUtility",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "TestableCombinePublishersTests",
            dependencies: ["TestableCombinePublishers"],
            path: "Tests/TestableCombinePublishersTests"
        ),
        .testTarget(
            name: "SwiftTestingTestableCombinePublishersTests",
            dependencies: ["SwiftTestingTestableCombinePublishers"],
            path: "Tests/SwiftTestingTestableCombinePublishersTests"
        ),
        .testTarget(
            name: "TestableCombinePublishersUtilityTests",
            dependencies: ["TestableCombinePublishersUtility"],
            path: "Tests/TestableCombinePublishersUtilityTests"
        ),
    ]
)
