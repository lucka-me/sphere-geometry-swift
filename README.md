# Sphere Geometry in Swift

[![](https://tokei.rs/b1/github/lucka-me/sphere-geometry-swift)](https://github.com/lucka-me/sphere-geometry-swift)

A core implementation of [S2 Geometry](https://github.com/google/s2geometry) in Swift.

## At a Glance

The `Cell` structure is focusing on geometry calculation like providing coordinates of verticies, while the `CellIdentifier` is focusing on indexing features.

The `CellCollection` works as an ordered container of `CellIdentifier`, providing some set operations like `union`, `difference` and `intersection`.

## Difference with C++ Implementation

Due to personal flavor, some of the concepts and naming in the original C++ implementation are changed.

| Concept / Class Name | Change |
| :--- | :---
| Face | `Zone`
| Face `0` ~ `6` | Named enum cases `africa` `asia` `north` `pacific` `america` and `south`
| Leaf-cell / IJ coordinate | `LeafCoordinate`
| `S2Cell` | `Cell`
| `S2CellId` | `CellIdentifier`
| `S2CellUnion` | `CellCollection`
| `S2Point` | `CartesianCoordinate`

`S2Shape`, `S2Region` and `S2RegionCoverer` are not implemented.

## Usage

To use the `SphereGeometry` library in a SwiftPM project, add it to the dependencies for your package and your target:

```swift
let package = Package(
    // ...
    dependencies: [
        // ...
        .package(url: "https://github.com/lucka-me/sphere-geometry-swift", branch: "main"), // Since we don't have any release yet
    ],
    targets: [
        // ...
        .target(
            // ...
            dependencies: [
                // ...
                .product(name: "SphereGeometry", package: "sphere-geometry-swift"),
            ]
        )
    ]
)
```

## Platform Availability

`SphereGeometry` depends on the `simd` module of Apple platform, therefore it's not available on Windows or Linux yet.
