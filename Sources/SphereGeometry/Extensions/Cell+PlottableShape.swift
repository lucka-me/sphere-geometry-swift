//
//  Cell+PlottableShape.swift
//  SphereGeometry
//
//  Created by Lucka on 2/10/2024.
//

#if canImport(CoreLocation)
import CoreLocation
import Foundation

public extension Cell {
    var plottableLocationCoordinateShape: [ CLLocationCoordinate2D ] {
        guard level > .min else {
            return coordinate.zone.flatShape
        }
        
        let step = LeafCoordinate.step(at: level)
        let lowerRightVertex = vertex(at: .lowerRight, step: step)
        let upperRightVertex = vertex(at: .upperRight, step: step)
        let upperLeftVertex = vertex(at: .upperLeft, step: step)

        var lowerLeftLocation = coordinate.locationCoordinate
        var lowerRightLocation = lowerRightVertex.locationCoordinate
        var upperRightLocation = upperRightVertex.locationCoordinate
        let upperLeftLocation = upperLeftVertex.locationCoordinate
        
        if coordinate.j == LeafCoordinate.scalarMiddle
            || upperRightVertex.i == LeafCoordinate.scalarMiddle {
            // Fix the edge sticking with the Antimerdian, +180 to -180
            switch coordinate.zone {
            case .pacific:
                if coordinate.j == LeafCoordinate.scalarMiddle {
                    lowerLeftLocation.longitude = -180
                    lowerRightLocation.longitude = -180
                }
            case .north:
                if (coordinate.j == LeafCoordinate.scalarMiddle)
                    && (coordinate.i >= LeafCoordinate.scalarMiddle) {
                    lowerLeftLocation.longitude = -180
                    lowerRightLocation.longitude = -180
                }
            case .south:
                if (upperRightVertex.i == LeafCoordinate.scalarMiddle)
                    && (upperRightVertex.j <= LeafCoordinate.scalarMiddle) {
                    lowerRightLocation.longitude = -180
                    upperRightLocation.longitude = -180
                }
            default: break
            }
        }

        return [
            lowerLeftLocation,
            lowerRightLocation,
            upperRightLocation,
            upperLeftLocation,
            lowerLeftLocation,
        ]
    }
}

fileprivate extension CLLocationCoordinate2D {
    mutating func crossAntimerdian() {
        longitude = longitude + 360
    }
}

fileprivate extension Zone {
    static private let vertexLatitude: Double = atan(1 / sqrt(2)) / .pi * 180
    
    var flatShape : [ CLLocationCoordinate2D ] {
        switch self {
        case .africa:
            [
                .init(latitude: -Self.vertexLatitude, longitude: -45),
                .init(latitude: -Self.vertexLatitude, longitude:  45),
                .init(latitude:  Self.vertexLatitude, longitude:  45),
                .init(latitude:  Self.vertexLatitude, longitude: -45),
                .init(latitude: -Self.vertexLatitude, longitude: -45),
            ]
        case .asia:
            [
                .init(latitude: -Self.vertexLatitude, longitude:  45),
                .init(latitude:  Self.vertexLatitude, longitude:  45),
                .init(latitude:  Self.vertexLatitude, longitude: 135),
                .init(latitude: -Self.vertexLatitude, longitude: 135),
                .init(latitude: -Self.vertexLatitude, longitude:  45),
            ]
        case .north:
            [
                .init(latitude: Self.vertexLatitude, longitude:   45),
                .init(latitude: Self.vertexLatitude, longitude:  135),
                .init(latitude: 45, longitude:  180),
                .init(latitude: 90, longitude:  180),
                .init(latitude: 90, longitude: -180),
                .init(latitude: 45, longitude: -180),
                .init(latitude: Self.vertexLatitude, longitude: -135),
                .init(latitude: Self.vertexLatitude, longitude:  -45),
                .init(latitude: Self.vertexLatitude, longitude:   45),
            ]
        case .pacific:
            [
                .init(latitude:  Self.vertexLatitude, longitude: 135),
                .init(latitude:  Self.vertexLatitude, longitude: 225),
                .init(latitude: -Self.vertexLatitude, longitude: 225),
                .init(latitude: -Self.vertexLatitude, longitude: 135),
                .init(latitude:  Self.vertexLatitude, longitude: 135),
            ]
        case .america:
            [
                .init(latitude:  Self.vertexLatitude, longitude: -135),
                .init(latitude: -Self.vertexLatitude, longitude: -135),
                .init(latitude: -Self.vertexLatitude, longitude:  -45),
                .init(latitude:  Self.vertexLatitude, longitude:  -45),
                .init(latitude:  Self.vertexLatitude, longitude: -135),
            ]
        case .south:
            [
                .init(latitude: -Self.vertexLatitude, longitude: -135),
                .init(latitude: -45, longitude: -180),
                .init(latitude: -90, longitude: -180),
                .init(latitude: -90, longitude:  180),
                .init(latitude: -45, longitude:  180),
                .init(latitude: -Self.vertexLatitude, longitude:  135),
                .init(latitude: -Self.vertexLatitude, longitude:   45),
                .init(latitude: -Self.vertexLatitude, longitude:  -45),
                .init(latitude: -Self.vertexLatitude, longitude: -135),
            ]
        }
    }
}

#endif // canImport(CoreLocation)
