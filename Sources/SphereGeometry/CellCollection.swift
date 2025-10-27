//
//  CellCollection.swift
//  SphereGeometry
//
//  Created by Lucka on 5/9/2024.
//

import Foundation

public struct CellCollection {
    public private(set) var cells: UnderlyingSequence = [ ]
    
    public init() { }
    
    public init<S: Sequence>(_ sequence: S) where S.Element == UnderlyingSequence.Element {
        cells = sequence.sorted()
        normalize()
    }
}

extension CellCollection : BinarySearchable, Equatable, Sendable {

}

extension CellCollection : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(Array(elements))
    }
}

extension CellCollection : RandomAccessCollection {
    public subscript(position: UnderlyingSequence.Index) -> UnderlyingSequence.Element {
        cells[position]
    }
    
    public var startIndex: UnderlyingSequence.Index {
        cells.startIndex
    }
    
    public var endIndex: UnderlyingSequence.Index {
        cells.endIndex
    }
}

public extension CellCollection {
    typealias UnderlyingSequence = [ CellIdentifier ]
}

public extension CellCollection {
    static var wholeSphere: Self {
        .guaranteed(cells: Zone.allCases.map { .whole(zone: $0) })
    }
}

public extension CellCollection {
    static func guaranteed(cells: UnderlyingSequence) -> Self {
        .init(guaranteed: cells)
    }
}

public extension CellCollection {
    func aligned(at level: Level) -> Set<Element> {
        cells.reduce(into: .init()) { result, element in
            if let parent = element.parent(at: level) {
                // Includes itself
                result.insert(parent)
            } else {
                result.formUnion(element.guaranteedChildren(at: level))
            }
        }
    }
    
    func expand(to level: Level) -> Self {
        var result = Self.init(
            guaranteed: self.cells.map { $0.parent(at: level) ?? $0 }
        )
        result.normalize()
        return result
    }
    
    mutating func expanding(to level: Level) {
        // TODO: Simplify
        for (index, cell) in cells.enumerated() {
            guard cell.level > level else {
                continue
            }
            cells[index] = cell.guaranteedParent(at: level)
        }
        normalize()
    }
}

public extension CellCollection {
    func index(after cell: CellIdentifier) -> UnderlyingSequence.Index {
        cells.upper(of: cell, comparedBy: CellIdentifier.entirelyBefore(lhs:rhs:))
    }

    func index(after cell: CellIdentifier, since index: Index) -> Index {
        cells.upper(
            of: cell,
            from: index,
            to: cells.endIndex,
            comparedBy: CellIdentifier.entirelyBefore(lhs:rhs:)
        )
    }
}

public extension CellCollection {
    func difference(_ other: Self) -> Self {
        .init(guaranteed: Self.makeDifference(lhs: self.cells, rhs: other))
    }
    
    mutating func formDifference(_ other: Self) {
        self.cells = Self.makeDifference(lhs: self.cells, rhs: other)
    }
}

public extension CellCollection {
    func intersection(_ element: Element) -> Self {
        let lower = self.cells.lower(of: element, comparedBy: Element.entirelyBefore(lhs:rhs:))
        guard lower < self.cells.endIndex else {
            return .init()
        }
        let upper = self.cells.upper(
            of: element,
            from: lower,
            to: self.cells.endIndex,
            comparedBy: Element.entirelyBefore(lhs:rhs:)
        )
        return .guaranteed(cells: .init(self.cells[lower ..< upper]))
    }
    
    func intersection(_ other: Self) -> Self {
        .init(guaranteed: Self.makeIntersection(lhs: self.cells, rhs: other.cells))
    }

    func intersects(_ element: Element) -> Bool {
        let index = self.cells.lower(of: element, comparedBy: Element.entirelyBefore(lhs:rhs:))
        return index < self.cells.endIndex && self.cells[index].intersects(element)
    }
    
    func intersects(_ other: Self) -> Bool {
        guard !self.isEmpty, !other.isEmpty else {
            return false
        }

        var selfIndex = self.startIndex
        var otherIndex = other.startIndex
        while selfIndex < self.endIndex, otherIndex < other.endIndex {
            let selfCell = self[selfIndex]
            let otherCell = other[otherIndex]
            guard !Element.entirelyBefore(lhs: selfCell, rhs: otherCell) else {
                selfIndex = self.lower(
                    of: otherCell,
                    from: selfIndex + 1,
                    to: self.endIndex,
                    comparedBy: Element.entirelyBefore(lhs:rhs:)
                )
                continue
            }
            guard !Element.entirelyBefore(lhs: otherCell, rhs: selfCell) else {
                otherIndex = other.lower(
                    of: selfCell,
                    from: otherIndex + 1,
                    to: other.endIndex,
                    comparedBy: Element.entirelyBefore(lhs:rhs:)
                )
                continue
            }
            return true
        }
        return false
    }
    
    mutating func formIntersection(_ other: Self) {
        self.cells = Self.makeIntersection(lhs: self.cells, rhs: other.cells)
    }
}

public extension CellCollection {
    func union(_ other: Self) -> Self {
        .init(cells + other.cells)
    }


    mutating func formUnion(_ other: Self) {
        guard !other.isEmpty else {
            return
        }
        guard !self.isEmpty else {
            cells = other.cells
            return
        }
        cells.append(contentsOf: other.cells)
        cells.sort()
        normalize()
    }
}

public extension CellCollection {
    func contains(_ cell: CellIdentifier) -> Bool {
        let lower = self.lower(of: cell, comparedBy: Element.entirelyBefore(lhs:rhs:))
        return lower != endIndex && self[lower].contains(cell)
    }
    
    func isStrictSubset(of other: Self) -> Bool {
        other.isStrictSuperset(of: self)
    }

    func isStrictSuperset(of other: Self) -> Bool {
        guard !other.isEmpty else { return true }
        guard !self.isEmpty else { return false }
        var selfIndex = self.cells.startIndex
        for otherCell in other.cells {
            // If our first cell ends before the one we need to contain, advance
            // where we start searching.
            if (Element.entirelyBefore(lhs: self.cells[selfIndex], rhs: otherCell)) {
                selfIndex = self.cells.lower(
                    of: otherCell,
                    from: selfIndex + 1,
                    to: self.cells.endIndex,
                    comparedBy: Element.entirelyBefore(lhs:rhs:)
                )
                // If we're at the end, we don't contain the current otherCell.
                guard selfIndex < self.cells.endIndex else {
                    return false
                }
            }
        }
        return true
    }
}

public extension CellCollection {
    mutating func insert(_ cell: CellIdentifier) -> (index: Index, inserted: Bool) {
        var (cellIndex, inserted) = cells.insert(cell)
        guard inserted else {
            return (cellIndex, false)
        }
        guard cellIndex == startIndex || !cells[cellIndex - 1].contains(cell) else {
            return (cellIndex - 1, false)
        }
        var iterateIndex = cellIndex
        while iterateIndex < endIndex, (iterateIndex - cellIndex) < 4 {
            // Check whether this cell is contained by the previous cell.
            if iterateIndex > startIndex, cells[iterateIndex - 1].contains(cells[iterateIndex]) {
                cells.remove(at: iterateIndex)
                if cellIndex == iterateIndex {
                    cellIndex -= 1
                }
                continue
            }
            // Discard any previous cells contained by this cell.
            while
                iterateIndex > startIndex,
                cells[iterateIndex].contains(cells[iterateIndex - 1])
            {
                cells.remove(at: iterateIndex - 1)
                iterateIndex -= 1
                if cellIndex > iterateIndex {
                    cellIndex = iterateIndex
                }
            }
            // Check whether the last 3 elements plus "id" can be collapsed into a
            // single parent cell.
            while
                iterateIndex > 3,
                areSiblings(startAt: iterateIndex - 3, and: cells[iterateIndex])
            {
                cells[iterateIndex] = cells[iterateIndex].parent
                cells.removeSubrange(iterateIndex - 3 ..< iterateIndex)
                iterateIndex -= 3
                if cellIndex > iterateIndex {
                    cellIndex = iterateIndex
                }
            }
            iterateIndex += 1
        }
        return (cellIndex, true)
    }
}

fileprivate extension CellCollection {
    init(guaranteed cells: UnderlyingSequence) {
        self.cells = cells
    }
}

fileprivate extension CellCollection {
    func areSiblings(startAt startIndex: Index, and lastCell: CellIdentifier) -> Bool {
        // A necessary (but not sufficient) condition is that the XOR of the four cells must be
        // zero. This is also very fast to test.
        guard
            (
                cells[startIndex].rawValue ^
                cells[startIndex + 1].rawValue ^
                cells[startIndex + 2].rawValue
            ) == lastCell.rawValue
        else {
            return false
        }

        // Now we do a slightly more expensive but exact test. First, compute a mask that blocks
        // out the two bits that encode the child position of "id" with respect to its parent, then
        // check that the other three children all agree with "mask".
        var mask = lastCell.leastSignificantBit << 1
        mask = ~(mask + (mask << 1))
        let masked = lastCell.rawValue & mask
        return (cells[startIndex].rawValue & mask) == masked &&
            (cells[startIndex + 1].rawValue & mask) == masked &&
            (cells[startIndex + 2].rawValue & mask) == masked &&
            !lastCell.isWholeZone
    }
    
    mutating func normalize() {
        var out = startIndex
        for cell in cells {
            // Check whether this cell is contained by the previous cell.
            if out > startIndex, cells[out - 1].contains(cell) {
                continue
            }
            // Discard any previous cells contained by this cell.
            while out > startIndex, cell.contains(cells[out - 1]) {
                out -= 1
            }
            // Check whether the last 3 elements plus "id" can be collapsed into a
            // single parent cell.
            var mutatedCell = cell
            while out >= 3, areSiblings(startAt: out - 3, and: mutatedCell) {
                mutatedCell = mutatedCell.parent
                out -= 3
            }
            cells[out] = mutatedCell
            out += 1
        }
        if cells.count != out {
            cells.removeLast(cells.count - out)
        }
    }
}

fileprivate extension CellCollection {
    static func makeDifference(lhs: UnderlyingSequence, rhs: Self) -> UnderlyingSequence {
        // TODO: Use set operations like makeIntersection(lhs:rhs:) to improve performance
        var difference = UnderlyingSequence()
        for cell in lhs {
            rhs.appendDifference(with: cell, to: &difference)
        }
        return difference
    }

    func appendDifference(with cell: CellIdentifier, to sequence: inout UnderlyingSequence) {
        guard self.intersects(cell) else {
            sequence.append(cell)
            return
        }
        guard !self.contains(cell) else {
            return
        }
        let children = cell.children
        for child in children {
            appendDifference(with: child, to: &sequence)
        }
    }
}

fileprivate extension CellCollection {
    static func makeIntersection(
        lhs: UnderlyingSequence,
        rhs: UnderlyingSequence
    ) -> UnderlyingSequence {
        // TODO: Modify self.cells to improve performance?
        var intersection = UnderlyingSequence()
        var lhsIndex = lhs.startIndex
        var rhsIndex = rhs.startIndex
        while lhsIndex < lhs.endIndex, rhsIndex < rhs.endIndex {
            let lhsCell = lhs[lhsIndex]
            let rhsCell = rhs[rhsIndex]
            let lhsMin = lhsCell.rawValueRangeMin
            let rhsMin = rhsCell.rawValueRangeMin
            if lhsMin > rhsMin {
                // Either rhsCell.contains(lhsCell) or the two cells are disjoint.
                if (lhsCell.rawValue <= rhsCell.rawValueRangeMax) {
                    intersection.append(lhsCell)
                    lhsIndex += 1
                } else {
                    // Advance "rhsIndex" to the first cell that might overlap lhsCell.
                    rhsIndex = rhs.lower(
                        of: lhsCell,
                        from: rhsIndex + 1,
                        to: rhs.endIndex,
                        comparedBy: Element.entirelyBefore(lhs:rhs:)
                    )
                }
            } else if (lhsMin < rhsMin) {
                // Identical to the code above with "lhsCell" and "rhsCell" reversed.
                if rhsCell.rawValue <= lhsCell.rawValueRangeMax {
                    intersection.append(rhsCell)
                    rhsIndex += 1
                } else {
                    lhsIndex = lhs.lower(
                        of: rhsCell,
                        from: lhsIndex + 1,
                        to: lhs.endIndex,
                        comparedBy: Element.entirelyBefore(lhs:rhs:)
                    )
                }
            } else {
                // "lhsCell" and "rhsCell" have the same rangeMin, so one contains the other.
                if (lhsCell.rawValue < rhsCell.rawValue) {
                    intersection.append(lhsCell)
                    lhsIndex += 1
                } else {
                    intersection.append(rhsCell)
                    rhsIndex += 1
                }
            }
        }
        return intersection
    }
}

fileprivate typealias UnderlyingBinarySearchable = BinarySearchable

extension CellCollection.UnderlyingSequence : UnderlyingBinarySearchable {
    
}

fileprivate extension CellCollection.UnderlyingSequence {
    @discardableResult
    mutating func insert(_ newElement: Element) -> (index: Index, inserted: Bool) {
        guard !isEmpty else {
            append(newElement)
            return (startIndex, true)
        }
        let upper = self.upper(of: newElement)
        guard upper > startIndex else {
            insert(newElement, at: upper)
            return (upper, true)
        }
        let shouldInsert = (self[upper - 1] < newElement)
        if shouldInsert {
            insert(newElement, at: upper)
        }
        return (upper, shouldInsert)
    }
}
