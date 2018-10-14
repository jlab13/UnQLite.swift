// swift-tools-version:4.0
import PackageDescription


let package = Package(
    name: "UnQLite.swift",
    products: [.library(name: "UnQLite", targets: ["CUnQLite", "UnQLite"])],
    targets: [
        .target(name: "CUnQLite"),
        .target(name: "UnQLite", dependencies: ["CUnQLite"]),
        .testTarget(name: "UnQLiteTests", dependencies: ["UnQLite"]),
    ],
    swiftLanguageVersions: [4]
)
