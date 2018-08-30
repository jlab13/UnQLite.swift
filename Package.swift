// swift-tools-version:4.0
import PackageDescription


let package = Package(
    name: "UnQLite",
    products: [
        .library(
            name: "UnQLite",
            targets: ["CUnQLite", "UnQLite"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CUnQLite",
            dependencies: []),
        .target(
            name: "UnQLite",
            dependencies: ["CUnQLite"]),
        .testTarget(
            name: "UnQLiteTests",
            dependencies: ["UnQLite"]),
    ]
)
