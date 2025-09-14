//
//  CellIdentifier.swift
//
//
//  Created by Lucka on 13/8/2024.
//

import Foundation

public struct CellIdentifier {
    public let rawValue: UInt64
    
    public init?(rawValue: RawValue) {
        guard Self.validate(rawValue) else {
            return nil
        }
        self.rawValue = rawValue
    }
}

public extension CellIdentifier {
    static func leaf(at coordinate: CartesianCoordinate) -> Self {
        return .leaf(at: coordinate.leafCoordinate)
    }
    
    init(_ coordinate: CartesianCoordinate, at level: Level) {
        self = .leaf(at: coordinate).guaranteedParent(at: level)
    }
    
    var cell: Cell {
        .init(identifier: self)
    }
}

public extension CellIdentifier {
    var level: Level {
        .guaranteed(rawValue: Level.max.rawValue - (UInt8(rawValue.trailingZeroBitCount) >> 1))
    }
}

public extension CellIdentifier {
    static func whole(zone: Zone) -> Self {
        .guaranteed(
            rawValue: (RawValue(zone.rawValue) << positionBits) + leastSignificantBit(at: .min)
        )
    }
    
    var isWholeZone: Bool {
        rawValue & (Self.leastSignificantBit(at: .min) - 1) == 0
    }
    
    var zone: Zone {
        .init(rawValue: .init(rawValue >> Self.positionBits))!
    }
}

public extension CellIdentifier {
    var children: [ Self ] {
        let childLeastSignificantBit = leastSignificantBit >> 2
        return [
            .guaranteed(rawValue: rawValue - 3 * childLeastSignificantBit),
            .guaranteed(rawValue: rawValue -     childLeastSignificantBit),
            .guaranteed(rawValue: rawValue +     childLeastSignificantBit),
            .guaranteed(rawValue: rawValue + 3 * childLeastSignificantBit),
        ]
    }
    
    var firstChild: Self {
        .guaranteed(rawValue: rawValue - 3 * (leastSignificantBit >> 2))
    }
    
    var lastChild: Self {
        .guaranteed(rawValue: rawValue + 3 * (leastSignificantBit >> 2))
    }
    
    func children(at level: Level) -> [ Self ] {
        switch self.level {
        case .min ..< level: guaranteedChildren(at: level)
        case level: [ self ]
        default: [ ]
        }
    }
    
    func firstChild(at level: Level) -> Self? {
        switch self.level {
        case .min ..< level: guaranteedFirstChild(at: level)
        case level: self
        default: nil
        }
    }
    
    func lastChild(at level: Level) -> Self? {
        switch self.level {
        case .min ..< level: guaranteedLastChild(at: level)
        case level: self
        default: nil
        }
    }
}

public extension CellIdentifier {
    var parent: CellIdentifier {
        let parentLeastSignificantBit = leastSignificantBit << 2
        return .guaranteed(
            rawValue: (rawValue & (~parentLeastSignificantBit + 1)) | parentLeastSignificantBit
        )
    }
    
    func parent(at level: Level) -> Self? {
        switch self.level {
        case .min ..< level: nil
        case level: self
        default: guaranteedParent(at: level)
        }
    }
}

public extension CellIdentifier {
    static func entirelyBefore(lhs: Self, rhs: Self) -> Bool {
        lhs.rawValueRangeMax < rhs.rawValueRangeMin
    }
    
    var range: ClosedRange<Self> {
        rangeMin ... rangeMax
    }
    
    var rangeMax: Self {
        .guaranteed(rawValue: rawValueRangeMax)
    }
    
    var rangeMin: Self {
        .guaranteed(rawValue: rawValueRangeMin)
    }

    func contains(_ other: CellIdentifier) -> Bool {
        rawValueRange.contains(other.rawValue)
    }
    
    func intersects(_ other: Self) -> Bool {
        other.rawValueRangeMin <= self.rawValueRangeMax &&
        other.rawValueRangeMax >= self.rawValueRangeMin
    }
}

public extension CellIdentifier {
    static func min(at level: Level) -> Self {
        if level == .min {
            whole(zone: .africa)
        } else {
            whole(zone: .africa).guaranteedFirstChild(at: level)
        }
    }
    
    static func max(at level: Level) -> Self {
        if level == .min {
            whole(zone: .south)
        } else {
            whole(zone: .south).guaranteedLastChild(at: level)
        }
    }
    
    static func range(at level: Level) -> ClosedRange<Self> {
        if level == .min {
            whole(zone: .africa) ... whole(zone: .south)
        } else {
            whole(zone: .africa).guaranteedFirstChild(at: level) ...
            whole(zone: .south).guaranteedLastChild(at: level)
        }
    }
}

extension CellIdentifier : Codable, Hashable, RawRepresentable, Sendable, Equatable {
    
}

extension CellIdentifier : Comparable {
    public static func < (lhs: CellIdentifier, rhs: CellIdentifier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension CellIdentifier : CustomStringConvertible {
    public var description: String {
        "#\(rawValue)"
    }
}

extension CellIdentifier : Strideable {
    private static let wrapOffset = RawValue(Zone.count) << positionBits
    
    public func advanced(by n: Int64) -> CellIdentifier {
        guard n != .zero else {
            return self
        }
        
        let shift = (Level.max.rawValue - self.level.rawValue) * 2 + 1
        let steps: Stride = if n < 0 {
            Swift.max(n, -Stride(self.rawValue >> shift))
        } else {
            Swift.min(n, Stride((Self.wrapOffset + leastSignificantBit - rawValue) >> shift))
        }
        
        return .guaranteed(rawValue: rawValue + (RawValue(steps) << shift))
    }
    
    public func distance(to other: CellIdentifier) -> Int64 {
        guard self != other else {
            return 0
        }
        
        let shift = (Level.max.rawValue - self.level.rawValue) * 2 + 1
        return if other > self {
            .init((other.rawValue - self.rawValue) >> shift)
        } else {
            -.init((self.rawValue - other.rawValue) >> shift)
        }
    }
}

extension CellIdentifier {
    static func guaranteed(rawValue: RawValue) -> Self {
        .init(guaranteed: rawValue)
    }
    
    static func validate(_ value: RawValue) -> Bool {
        (value >> positionBits) < Zone.count && ((value & (~value &+ 1)) & 0x1555555555555555 != 0)
    }
    
    private init(guaranteed rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension CellIdentifier {
    typealias Position = UInt64
    
    static let zoneBits: UInt8 = 3
    static let zoneMask: RawValue = 0b111 << positionBits
    
    static let positionBits: UInt8 = 2 * Level.max.rawValue + 1
    static let positionMask: RawValue = RawValue.max >> zoneBits
    
    init(zone: Zone, position: Position, level: Level) {
        let value = RawValue(zone.rawValue) << Self.positionBits + (position | 1)
        let leastSignificantBit = Self.leastSignificantBit(at: level)
        rawValue = (value & (~leastSignificantBit + 1)) | leastSignificantBit
    }
    
    var position: Position {
        rawValue & Self.positionMask
    }
}

extension CellIdentifier {
    private static let leafInvertMask: UInt8 = 0x02
    private static let leafSwapMask: UInt8 = 0x01
    
    static func leaf(at coordinate: LeafCoordinate) -> Self {
        var value = RawValue(coordinate.zone.rawValue) << (Self.positionBits - 1)
        var bits = RawValue(coordinate.zone.rawValue & Self.leafSwapMask)
        for index : RawValue in (0 ... 7).reversed() {
            let mask: RawValue = (1 << HilbertTable.lookupBits) - 1
            bits += ((RawValue(coordinate.i) >> (index * HilbertTable.lookupBits)) & mask) << (HilbertTable.lookupBits + 2)
            bits += ((RawValue(coordinate.j) >> (index * HilbertTable.lookupBits)) & mask) << 2
            bits = .init(HilbertTable.positions[Int(bits)])
            value |= (bits >> 2) << (index * 2 * HilbertTable.lookupBits)
            bits &= RawValue(Self.leafSwapMask | Self.leafInvertMask)
        }
        return .guaranteed(rawValue: value * 2 + 1)
    }
    
    var leafCoordinate: LeafCoordinate {
        let zone = self.zone
        var bits = RawValue(zone.rawValue & Self.leafSwapMask)
        var value : LeafCoordinate.Coordinate = .init(x: 0, y: 0)
        for index : RawValue in (0 ... 7).reversed() {
            let bitsCount = (index < 7) ? HilbertTable.lookupBits : (UInt64(Level.max.rawValue) - 7 * HilbertTable.lookupBits)
            bits += ((rawValue >> (index * 2 * HilbertTable.lookupBits + 1)) & ((1 << (2 * bitsCount)) - 1)) << 2
            bits = .init(HilbertTable.cells[Int(bits)])
            value.x += UInt32(bits >> (HilbertTable.lookupBits + 2)) << (index * HilbertTable.lookupBits)
            value.y += UInt32((bits >> 2) & ((1 << HilbertTable.lookupBits) - 1)) << (index * HilbertTable.lookupBits)
            bits &= RawValue(Self.leafSwapMask | Self.leafInvertMask)
        }
        return .init(zone: zone, coordinate: value)
    }
}

extension CellIdentifier {
    func guaranteedChildren(at level: Level) -> [ Self ] {
        let selfLeastSignificantBit = self.leastSignificantBit
        let childrenLeastSignificantBit = Self.leastSignificantBit(at: level)
        return Swift.stride(
            from: rawValue - selfLeastSignificantBit + childrenLeastSignificantBit,
            to: rawValue + selfLeastSignificantBit + childrenLeastSignificantBit,
            by: .init(childrenLeastSignificantBit << 1)
        )
        .map(Self.guaranteed(rawValue:))
    }
    
    func guaranteedFirstChild(at level: Level) -> Self {
        .guaranteed(rawValue: rawValue - leastSignificantBit + Self.leastSignificantBit(at: level))
    }
    
    func guaranteedLastChild(at level: Level) -> Self {
        .guaranteed(rawValue: rawValue + leastSignificantBit - Self.leastSignificantBit(at: level))
    }
}

extension CellIdentifier {
    func guaranteedParent(at level: Level) -> Self {
        let parentLeastSignificantBit = Self.leastSignificantBit(at: level)
        return .guaranteed(rawValue: (rawValue & (~parentLeastSignificantBit + 1)) | parentLeastSignificantBit)
    }
}

extension CellIdentifier {
    var rawValueRange: ClosedRange<RawValue> {
        let leastSignificantBit = self.leastSignificantBit - 1
        return (rawValue - leastSignificantBit) ... (rawValue + leastSignificantBit)
    }
    
    var rawValueRangeMax: RawValue {
        rawValue + (leastSignificantBit - 1)
    }
    
    var rawValueRangeMin: RawValue {
        rawValue - (leastSignificantBit - 1)
    }
}

extension CellIdentifier {
    static func leastSignificantBit(at level: Level) -> RawValue {
        1 << (2 * (Level.max.rawValue - level.rawValue))
    }
    
    var leastSignificantBit: RawValue {
        rawValue & (~rawValue + 1)
    }
}
