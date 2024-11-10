//
//  CLLocationCoordinate2D+SphereGeometry.swift
//
//
//  Created by Lucka on 2/9/2024.
//

#if canImport(CoreLocation)
import CoreLocation

public extension CLLocationCoordinate2D {
    var cartesianCoordinate: CartesianCoordinate {
        let radianLongitude = self.radianLongitude
        let radianLatitude = self.radianLatitude
        let cosLatitude = cos(radianLatitude)
        return .init(
            x: cos(radianLongitude) * cosLatitude,
            y: sin(radianLongitude) * cosLatitude,
            z: sin(radianLatitude)
        )
    }
    
    var leafCell: Cell {
        .init(cartesianCoordinate, at: .max)
    }
    
    var leafCellIdentifier : CellIdentifier {
        .leaf(at: cartesianCoordinate)
    }
    
    func cell(at level: Level) -> Cell {
        .init(cartesianCoordinate, at: level)
    }
    
    func cellIdentifier(at level: Level) -> CellIdentifier {
        .init(cartesianCoordinate, at: level)
    }
}

public extension CartesianCoordinate {
    var locationCoordinate: CLLocationCoordinate2D {
        .init(latitude: degreeLatitude, longitude: degreeLongitude)
    }
}

public extension LeafCoordinate {
    var locationCoordinate: CLLocationCoordinate2D {
        cartesianCoordinate.locationCoordinate
    }
}

extension CLLocationCoordinate2D {
    var radianLatitude: Double {
        get {
            self.latitude * .pi / 180
        }
        set {
            self.latitude = newValue * 180 / .pi
        }
    }
    
    var radianLongitude: Double {
        get {
            self.longitude * .pi / 180
        }
        set {
            self.longitude = newValue * 180 / .pi
        }
    }
}

#endif // canImport(CoreLocation)
