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
    static let zoneBits: UInt8 = 3
    
    static func entirelyBefore(lhs: Self, rhs: Self) -> Bool {
        lhs.rangeMax < rhs.rangeMin
    }
    
    static func whole(zone: Zone) -> Self {
        .guaranteed(rawValue: (RawValue(zone.rawValue) << positionBits) + leastSignificantBit(at: .min))
    }
    
    static func leaf(at coordinate: CartesianCoordinate) -> Self {
        return .leaf(at: coordinate.leafCoordinate)
    }
    
    init(_ coordinate: CartesianCoordinate, at level: Level) {
        self = .leaf(at: coordinate).parent(at: level)
    }
    
    var cell: Cell {
        .init(identifier: self)
    }
    
    var children: [ Self ] {
        let childLeastSignificantBit = leastSignificantBit >> 2
        return [
            .guaranteed(rawValue: rawValue - 3 * childLeastSignificantBit),
            .guaranteed(rawValue: rawValue -     childLeastSignificantBit),
            .guaranteed(rawValue: rawValue +     childLeastSignificantBit),
            .guaranteed(rawValue: rawValue + 3 * childLeastSignificantBit),
        ]
    }
    
    var isWholeZone: Bool {
        rawValue & (Self.leastSignificantBit(at: .min) - 1) == 0
    }
    
    var level: Level {
        .init(rawValue: Level.max.rawValue - (UInt8(rawValue.trailingZeroBitCount) >> 1))!
    }
    
    var parent: CellIdentifier {
        let parentLeastSignificantBit = leastSignificantBit << 2
        return .guaranteed(rawValue: (rawValue & (~parentLeastSignificantBit + 1)) | parentLeastSignificantBit)
    }
    
    var range: ClosedRange<RawValue> {
        let leastSignificantBit = self.leastSignificantBit - 1
        return (rawValue - leastSignificantBit) ... (rawValue + leastSignificantBit)
    }
    
    var rangeMax: RawValue {
        rawValue + (leastSignificantBit - 1)
    }
    
    var rangeMin: RawValue {
        rawValue - (leastSignificantBit - 1)
    }
    
    var zone: Zone {
        .init(rawValue: .init(rawValue >> Self.positionBits))!
    }
    
    func children(at level: Level) -> [ Self ] {
        let selfLevel = self.level
        guard level > selfLevel else {
            return [ self ]
        }
        let childrenLeastSignificantBit = Self.leastSignificantBit(at: level)
        let start = rawValue - self.leastSignificantBit + childrenLeastSignificantBit
        let steps = UInt64(level.rawValue - selfLevel.rawValue) * 4
        return (0 ..< steps).map { step in
            .guaranteed(rawValue: start + (step * (childrenLeastSignificantBit << 1)))
        }
    }

    func contains(_ other: CellIdentifier) -> Bool {
        range.contains(other.rawValue)
    }
    
    func intersects(_ other: Self) -> Bool {
        other.rangeMin <= self.rangeMax && other.rangeMax >= self.rangeMin
    }
    
    func parent(at level: Level) -> CellIdentifier? {
        guard self.level > level else {
            return nil
        }
        let parentLeastSignificantBit = Self.leastSignificantBit(at: level)
        return .guaranteed(rawValue: (rawValue & (~parentLeastSignificantBit + 1)) | parentLeastSignificantBit)
    }
}

extension CellIdentifier : Codable, Comparable, CustomStringConvertible, Equatable, Hashable, RawRepresentable, Sendable {
    public static func < (lhs: CellIdentifier, rhs: CellIdentifier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        "#\(rawValue)"
    }
}

extension CellIdentifier {
    typealias Position = UInt64
    
    static let invertMask: UInt8 = 0x02
    
    static let positionBits: UInt8 = 2 * Level.max.rawValue + 1
    static let positionMask: RawValue = RawValue.max >> zoneBits
    
    static let swapMask: UInt8 = 0x01
    static let zoneMask: RawValue = 0b111 << positionBits
    
    static func guaranteed(rawValue: RawValue) -> Self {
        .init(guaranteed: rawValue)
    }
    
    static func leaf(at coordinate: LeafCoordinate) -> Self {
        var value = RawValue(coordinate.zone.rawValue) << (Self.positionBits - 1)
        var bits = RawValue(coordinate.zone.rawValue & Self.swapMask)
        for index : RawValue in (0 ... 7).reversed() {
            let mask: RawValue = (1 << HilbertTable.lookupBits) - 1
            bits += ((RawValue(coordinate.i) >> (index * HilbertTable.lookupBits)) & mask) << (HilbertTable.lookupBits + 2)
            bits += ((RawValue(coordinate.j) >> (index * HilbertTable.lookupBits)) & mask) << 2
            bits = .init(HilbertTable.positions[Int(bits)])
            value |= (bits >> 2) << (index * 2 * HilbertTable.lookupBits)
            bits &= RawValue(Self.swapMask | Self.invertMask)
        }
        return .guaranteed(rawValue: value * 2 + 1)
    }
    
    static func leastSignificantBit(at level: Level) -> RawValue {
        1 << (2 * (Level.max.rawValue - level.rawValue))
    }
    
    static func validate(_ value: RawValue) -> Bool {
        (value >> positionBits) < Zone.count && ((value & (~value &+ 1)) & 0x1555555555555555 != 0)
    }

    init(zone: Zone, position: Position, level: Level) {
        let value = RawValue(zone.rawValue) << Self.positionBits + (position | 1)
        let leastSignificantBit = Self.leastSignificantBit(at: level)
        rawValue = (value & (~leastSignificantBit + 1)) | leastSignificantBit
    }
    
    var leastSignificantBit: RawValue {
        rawValue & (~rawValue + 1)
    }
    
    var position: Position {
        rawValue & Self.positionMask
    }
    
    var leafCoordinate: LeafCoordinate {
        let zone = self.zone
        var bits = RawValue(zone.rawValue & Self.swapMask)
        var value : LeafCoordinate.Coordinate = .init(x: 0, y: 0)
        for index : RawValue in (0 ... 7).reversed() {
            let bitsCount = (index < 7) ? HilbertTable.lookupBits : (UInt64(Level.max.rawValue) - 7 * HilbertTable.lookupBits)
            bits += ((rawValue >> (index * 2 * HilbertTable.lookupBits + 1)) & ((1 << (2 * bitsCount)) - 1)) << 2
            bits = .init(HilbertTable.cells[Int(bits)])
            value.x += UInt32(bits >> (HilbertTable.lookupBits + 2)) << (index * HilbertTable.lookupBits)
            value.y += UInt32((bits >> 2) & ((1 << HilbertTable.lookupBits) - 1)) << (index * HilbertTable.lookupBits)
            bits &= RawValue(Self.swapMask | Self.invertMask)
        }
        return .init(zone: zone, coordinate: value)
    }
    
    func parent(at level: Level) -> CellIdentifier {
        let parentLeastSignificantBit = Self.leastSignificantBit(at: level)
        return .guaranteed(rawValue: (rawValue & (~parentLeastSignificantBit + 1)) | parentLeastSignificantBit)
    }
}

fileprivate extension CellIdentifier {
    init(guaranteed rawValue: RawValue) {
        self.rawValue = rawValue
    }
}
