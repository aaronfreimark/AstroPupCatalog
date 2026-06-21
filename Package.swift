// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AstroPupCatalog",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "AstroPupCatalog", targets: ["AstroPupCatalog"]),
    ],
    targets: [
        .target(
            name: "AstroPupCatalog",
            resources: [.copy("Catalog")]
        ),
        .testTarget(
            name: "AstroPupCatalogTests",
            dependencies: ["AstroPupCatalog"]
        ),
    ]
)
