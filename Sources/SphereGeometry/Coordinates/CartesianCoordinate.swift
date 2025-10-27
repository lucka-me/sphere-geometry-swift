//
//  CartesianCoordinate.swift
//
//
//  Created by Lucka on 13/8/2024.
//

import simd

///< (X, Y, Z) Coordinate
public struct CartesianCoordinate {
    public let rawValue: SIMD3<Double>
    
    public init(rawValue: SIMD3<Double>) {
        self.rawValue = normalize(rawValue)
    }
}

public extension CartesianCoordinate {
    typealias Scalar = RawValue.Scalar
    
    init(x: Scalar, y: Scalar, z: Scalar) {
        rawValue = normalize(.init(x: x, y: y, z: z))
    }
    
    var degreeLatitude: Double {
        radianLatitude * 180 / .pi
    }

    var degreeLongitude: Double {
        radianLongitude * 180 / .pi
    }
    
    var leafCell: Cell {
        .init(leafCoordinate, at: .max)
    }

    var leafCoordinate: LeafCoordinate {
        let zone = self.zone
        
        ///< XYZ to UV
        let uv = zone.project(rawValue)
        ///< UV to ST
        let uvSign = sign(uv)
        let quadratic =
            ((uv * 3 * uvSign + 1).squareRoot() * 0.5 * uvSign)
            - uvSign.replacing(with: 0, where: uvSign .> [ 0, 0 ])
        let leaf = clamp(
            LeafCoordinate.Coordinate(quadratic * Double(LeafCoordinate.scalarMax) - 0.5),
            min: 0,
            max: LeafCoordinate.scalarMax - 1
        )
        
        return .init(zone: zone, coordinate: leaf)
    }
    
    var radianLatitude: Double {
        atan2(rawValue.z + 0, hypot(rawValue.x, rawValue.y))
    }

    var radianLongitude: Double {
        atan2(rawValue.y + 0, rawValue.x + 0)
    }
    
    var zone: Zone {
        let absolute = abs(rawValue)
        var index = if absolute[0] > absolute[1] {
            absolute[0] > absolute[2] ? 0 : 2
        } else {
            absolute[1] > absolute[2] ? 1 : 2
        }
        if (rawValue[index] < 0) {
            index += 3
        }
        return .init(rawValue: .init(index))!
    }
    
    func arc(to other: Self) -> Double {
        acos(dot(self.rawValue, other.rawValue))
    }
}

extension CartesianCoordinate : RawRepresentable {
    
}

fileprivate extension Zone {
    func project(_ coordinate: CartesianCoordinate.RawValue) -> SIMD2<Double> {
        switch self {
        case .africa:
            return .init(x: coordinate.y / coordinate.x, y: coordinate.z / coordinate.x)
        case .asia:
            return .init(x: -coordinate.x / coordinate.y, y: coordinate.z / coordinate.y)
        case .north:
            return .init(x: -coordinate.x / coordinate.z, y: -coordinate.y / coordinate.z)
        case .pacific:
            return .init(x: coordinate.z / coordinate.x, y: coordinate.y / coordinate.x)
        case .america:
            return .init(x: coordinate.z / coordinate.y, y: -coordinate.x / coordinate.y)
        case .south:
            return .init(x: -coordinate.y / coordinate.z, y: -coordinate.x / coordinate.z)
        }
    }
}
