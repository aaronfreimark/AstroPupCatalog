// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AstroPupCatalog",
    defaultLocalization: "en",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "AstroPupCatalog", targets: ["AstroPupCatalog"]),
    ],
    targets: [
        .target(
            name: "AstroPupCatalog",
            resources: [.copy("Catalog"), .process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "AstroPupCatalogTests",
            dependencies: ["AstroPupCatalog"]
        ),
    ]
)
