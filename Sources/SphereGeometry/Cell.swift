//
//  Cell.swift
//  
//
//  Created by Lucka on 1/9/2024.
//

import simd
import Foundation

public struct Cell {
    public let level: Level
    public let coordinate: LeafCoordinate
    
    public init(identifier: CellIdentifier) {
        self.level = identifier.level
        self.coordinate = identifier.leafCoordinate.round(to: self.level)
    }
    
    public init(_ coordinate: CartesianCoordinate, at level: Level) {
        self.level = level
        self.coordinate = coordinate.leafCoordinate.round(to: level)
    }
}

public extension Cell {
    var area: Double {
        let step = LeafCoordinate.step(at: level)
        let lowerLeftVertex = coordinate.cartesianCoordinate
        let lowerRightVertex = vertex(at: .lowerRight, step: step).cartesianCoordinate
        let upperRightVertex = vertex(at: .upperRight, step: step).cartesianCoordinate
        let upperLeftVertex = vertex(at: .upperLeft, step: step).cartesianCoordinate
        return Self.area(lowerLeftVertex, lowerRightVertex, upperRightVertex) +
        Self.area(lowerLeftVertex, upperRightVertex, upperLeftVertex)
    }
    
    var children: [ Self ] {
        let childLevel = level.advanced(by: 1)
        let step = LeafCoordinate.step(at: childLevel)
        return [
            .init(level: childLevel, coordinate: coordinate),
            .init(
                level: childLevel,
                coordinate: .init(zone: zone, coordinate: coordinate.coordinate &+ [ 0, step ])
            ),
            .init(
                level: childLevel,
                coordinate: .init(zone: zone, coordinate: coordinate.coordinate &+ [ step, step ])
            ),
            .init(
                level: childLevel,
                coordinate: .init(zone: zone, coordinate: coordinate.coordinate &+ [ step, 0 ])
            ),
        ]
    }
    
    var identifier: CellIdentifier {
        .leaf(at: coordinate).parent(guaranteed: level)
    }
    
    var vertices: [ LeafCoordinate ] {
        let step = LeafCoordinate.step(at: level)
        return VertexPosition.allCases.map { vertex(at: $0, step: step) }
    }
    
    var zone: Zone {
        coordinate.zone
    }
    
    func intersects(_ other: Self) -> Bool {
        guard self.coordinate.zone == other.coordinate.zone else {
            return false
        }
        let selfStep = LeafCoordinate.step(at: self.level)
        let otherStep = LeafCoordinate.step(at: other.level)
        guard
            (self.coordinate.i ... self.coordinate.i + selfStep)
                .overlaps(other.coordinate.i ... other.coordinate.i + otherStep),
            (self.coordinate.j ... self.coordinate.j + selfStep)
                .overlaps(other.coordinate.j ... other.coordinate.j + otherStep)
        else {
            return false
        }
        return true
    }
}

extension Cell {
    enum VertexPosition {
        case lowerLeft
        case lowerRight
        case upperRight
        case upperLeft
    }
    
    init(level: Level, coordinate: LeafCoordinate) {
        self.level = level
        self.coordinate = coordinate
    }
    
    func vertex(
        at position: VertexPosition, step: LeafCoordinate.Scalar
    ) -> LeafCoordinate {
        .init(
            zone: coordinate.zone,
            coordinate: coordinate.coordinate &+ (position.offset &* step)
        )
    }
    
    func vertex(at position: VertexPosition) -> LeafCoordinate {
        .init(
            zone: coordinate.zone,
            coordinate: coordinate.coordinate &+ (position.offset &* LeafCoordinate.step(at: level))
        )
    }
}

extension Cell.VertexPosition : CaseIterable {
    
}

extension Cell.VertexPosition {
    var offset: LeafCoordinate.Coordinate {
        switch self {
        case .lowerLeft:
            [ 0, 0 ]
        case .lowerRight:
            [ 1, 0 ]
        case .upperRight:
            [ 1, 1 ]
        case .upperLeft:
            [ 0, 1 ]
        }
    }
}

fileprivate extension Cell {
    static func area(_ a: CartesianCoordinate, _ b: CartesianCoordinate, _ c: CartesianCoordinate) -> Double {
        let angles = SIMD4(0, b.arc(to: c), c.arc(to: a), a.arc(to: b))
        let s = 0.5 * angles.sum()
        // Use l'Huilier's formula.
        let tangentProduct: Double
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let components: SIMD4 = tan(0.5 * (s - angles))
            tangentProduct = components.w * components.x * components.y * components.z
        } else {
            let components: SIMD4 = 0.5 * (s - angles)
            tangentProduct = tan(components.w) * tan(components.x) * tan(components.y) * tan(components.z)
        }
        
        return 4 * atan(sqrt(max(0.0, tangentProduct))) * Earth.radius * Earth.radius
    }
}
