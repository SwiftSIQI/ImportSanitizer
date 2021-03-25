// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImportSanitizer",
    products: [
        .executable(name: "importsanitizer", targets: ["ImportSanitizer"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/JohnSundell/Files",
            from: "4.1.1"
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "0.3.1"
        ),
        .package(
            url: "https://github.com/onevcat/Rainbow",
            from: "3.2.0"),
        .package(
            url: "https://github.com/mxcl/Path.swift.git",
            from: "1.2.0")
    ],
    targets: [
        .target(
            name: "ImportSanitizer",
            dependencies: [
                "ImportSanitizerCore",
                .product(name: "Rainbow",
                         package: "Rainbow")]),
        .target(
            name: "ImportSanitizerCore",
            dependencies: [
                .product(name: "Files",
                         package: "Files"),
                .product(name: "Rainbow",
                         package: "Rainbow"),
                .product(name: "ArgumentParser",
                         package: "swift-argument-parser"),
                .product(name: "Path",
                         package: "Path.swift")
            ]
        )
    ]
)
