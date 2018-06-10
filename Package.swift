// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pcg-swift",
    products: [
        .library(
            name: "PermutedCongruentialGenerator",
            targets: ["PermutedCongruentialGenerator"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PermutedCongruentialGenerator",
            dependencies: []),
        .testTarget(
            name: "PermutedCongruentialGeneratorTests",
            dependencies: ["PermutedCongruentialGenerator"]),
    ]
)
