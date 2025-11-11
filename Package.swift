// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SphereGeometry",
    products: [
        .library(
            name: "SphereGeometry",
            targets: [
                "SphereGeometry",
                "BinarySearch"
            ]
        ),
    ],
    targets: [
        .target(name: "SphereGeometry", dependencies: [ .target(name: "BinarySearch") ]),
        .target(name: "BinarySearch")
    ]
)
