//
//  CellCoordinate.swift
//
//
//  Created by Lucka on 15/8/2024.
//

import simd

///< (I, J) Coordinate
///<    Leaf-cell coordinates.  "i" and "j" are integers in the range
///<    [0,(2**30)-1] that identify a particular leaf cell on the given face.
///<    The (i, j) coordinate system is right-handed on each face, and the
///<    faces are oriented such that Hilbert curves connect continuously from
///<    one face to the next.
public struct LeafCoordinate {
    public let zone: Zone
    public let coordinate: Coordinate
}

public extension LeafCoordinate {
    typealias Coordinate = SIMD2<Scalar>
    typealias Scalar = UInt32
    
    static let scalarMax: Scalar = 1 << Level.max.rawValue
    static let scalarMiddle = scalarMax / 2

    static func step(at level: Level) -> Scalar {
        1 << (Level.max.rawValue - level.rawValue)
    }
    
    init(zone: Zone, i: Scalar, j: Scalar) {
        self.zone = zone
        self.coordinate = .init(i, j)
    }
    
    var i: Scalar {
        coordinate.x
    }
    
    var j: Scalar {
        coordinate.y
    }
    
    var cartesianCoordinate: CartesianCoordinate {
        let st = SIMD2<Double>(coordinate) / Double(Self.scalarMax)
        let stSign = sign(st - 0.5)
        let stFlipped = st + stSign.replacing(with: 0, where: stSign .> [ 0, 0 ])
        return .init(rawValue: zone.project(uv: stSign * (stFlipped * stFlipped * 4 - 1) * Double(1.0 / 3.0)))
    }
    
    func round(to level: Level) -> Self {
        let step = Self.step(at: level)
        return .init(zone: zone, coordinate: coordinate & (0 &- step))
    }
}

extension LeafCoordinate : Equatable, CustomStringConvertible {
    public var description: String {
        "#\(zone), (\(coordinate.x),\(coordinate.y))"
    }
}

fileprivate extension Zone {
    func project(uv: SIMD2<Double>) -> SIMD3<Double> {
        switch self {
        case .africa:
            return .init(x: 1, y: uv.x, z: uv.y)
        case .asia:
            return .init(x: -uv.x, y: 1, z: uv.y)
        case .north:
            return .init(x: -uv.x, y: -uv.y, z: 1)
        case .pacific:
            return .init(x: -1, y: -uv.y, z: -uv.x)
        case .america:
            return .init(x: uv.y, y: -1, z: -uv.x)
        case .south:
            return .init(x: uv.y, y: uv.x, z: -1)
        }
    }
}
