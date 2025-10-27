//
//  Zone.swift
//  SphereGeometry
//
//  Created by Lucka on 13/8/2024.
//

import Foundation

public enum Zone : UInt8 {
    case africa     = 0
    case asia       = 1
    case north      = 2
    case pacific    = 3
    case america    = 4
    case south      = 5
}

extension Zone : CaseIterable, Hashable {
    
}

extension Zone : Comparable {
    public static func < (lhs: Zone, rhs: Zone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public extension Zone {
    static let count: RawValue = 6
}
