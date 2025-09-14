//
//  Constants.swift
//  
//
//  Created by Lucka on 13/8/2024.
//

import Foundation

public struct Level {
    public private(set) var rawValue: UInt8
    
    public init?(rawValue: RawValue) {
        guard Self.min.rawValue <= rawValue && rawValue <= Self.max.rawValue else {
            return nil
        }
        self.rawValue = rawValue
    }
}

public extension Level {
    static let at = (
        Self.guaranteed(rawValue: 0),
        Self.guaranteed(rawValue: 1),
        Self.guaranteed(rawValue: 2),
        Self.guaranteed(rawValue: 3),
        Self.guaranteed(rawValue: 4),
        Self.guaranteed(rawValue: 5),
        Self.guaranteed(rawValue: 6),
        Self.guaranteed(rawValue: 7),
        Self.guaranteed(rawValue: 8),
        Self.guaranteed(rawValue: 9),
        Self.guaranteed(rawValue: 10),
        Self.guaranteed(rawValue: 11),
        Self.guaranteed(rawValue: 12),
        Self.guaranteed(rawValue: 13),
        Self.guaranteed(rawValue: 14),
        Self.guaranteed(rawValue: 15),
        Self.guaranteed(rawValue: 16),
        Self.guaranteed(rawValue: 17),
        Self.guaranteed(rawValue: 18),
        Self.guaranteed(rawValue: 19),
        Self.guaranteed(rawValue: 20),
        Self.guaranteed(rawValue: 21),
        Self.guaranteed(rawValue: 22),
        Self.guaranteed(rawValue: 23),
        Self.guaranteed(rawValue: 24),
        Self.guaranteed(rawValue: 25),
        Self.guaranteed(rawValue: 26),
        Self.guaranteed(rawValue: 27),
        Self.guaranteed(rawValue: 28),
        Self.guaranteed(rawValue: 29),
        Self.guaranteed(rawValue: 30)
    )

    static let min: Self = .at.0
    static let max: Self = .at.30
    
    static func clamp(_ rawValue: RawValue, min: Self = .min, max: Self = .max) -> Self {
        .guaranteed(rawValue: rawValue.clamped(to: min.rawValue ... max.rawValue))
    }
    
    static func with(minimalWidth: Double) -> Self {
        let value = ilogb(minimalWidthDerivative / (minimalWidth / Earth.radius))
        return .init(guaranteed: .init(value.clamped(to: Int32(Self.min.rawValue) ... Int32(Self.max.rawValue))))
    }
    
    var averageArea: Double {
        scalbn(Self.averageAreaDerivative, -2 * .init(rawValue))
    }
}

extension Level : Equatable, RawRepresentable, Sendable {
    
}

extension Level : Comparable {
    public static func < (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Level : Strideable {
    public func advanced(by n: Int8) -> Level {
        if n > 0 {
            if Self.max.rawValue - rawValue < n {
                Self.max
            } else {
                .guaranteed(rawValue: rawValue + RawValue(n))
            }
        } else {
            if rawValue < -n {
                Self.min
            } else {
                .guaranteed(rawValue: RawValue(Stride(rawValue) + n))
            }
        }
    }
    
    public func distance(to other: Level) -> Int8 {
        .init(rawValue.distance(to: other.rawValue))
    }
}

extension Level {
    static func guaranteed(rawValue: RawValue) -> Self {
        .init(guaranteed: rawValue)
    }
}

fileprivate extension Level {
    static let minimalWidthDerivative: Double = 2 * sqrt(2) / 3
    static let averageAreaDerivative: Double = 4 * .pi / 6
    
    init(guaranteed rawValue: RawValue) {
        self.rawValue = rawValue
    }
}
