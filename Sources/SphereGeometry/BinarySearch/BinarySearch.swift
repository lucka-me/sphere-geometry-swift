//
//  BinarySearch.swift
//  SphereGeometry
//
//  Created by Lucka on 28/10/2025.
//

import Foundation

public enum BinarySearch {
}

public extension BinarySearch {
    static func lower<C: BidirectionalCollection, T>(
        of value: T,
        in collection: C,
        from startIndex: C.Index,
        to endIndex: C.Index,
        comparedBy compare: (C.Element, T) -> Bool
    ) -> C.Index {
        var first = startIndex
        var count = collection.distance(from: first, to: endIndex)
        while count > 0 {
            let step = count / 2
            let it = collection.index(first, offsetBy: step)
            if (compare(collection[it], value)) {
                first = collection.index(after: it)
                count -= step + 1
            } else {
                count = step
            }
        }
        return first
    }
    
    static func lower<C: BidirectionalCollection, T>(
        of value: T,
        in collection: C,
        comparedBy compare: (C.Element, T) -> Bool
    ) -> C.Index {
        return lower(
            of: value,
            in: collection,
            from: collection.startIndex,
            to: collection.endIndex,
            comparedBy: compare
        )
    }
    
    static func lower<C: BidirectionalCollection>(
        of value: C.Element,
        in collection: C,
        from startIndex: C.Index,
        to endIndex: C.Index
    ) -> C.Index where C.Element : Comparable {
        return lower(of: value, in: collection, from: startIndex, to: endIndex, comparedBy: <)
    }
    
    static func lower<C: BidirectionalCollection>(
        of value: C.Element,
        in collection: C
    ) -> C.Index where C.Element : Comparable {
        return lower(
            of: value,
            in: collection,
            from: collection.startIndex,
            to: collection.endIndex
        )
    }
}

public extension BinarySearch {
    static func upper<C: BidirectionalCollection, T>(
        of value: T,
        in collection: C,
        from startIndex: C.Index,
        to endIndex: C.Index,
        comparedBy compare: (T, C.Element) -> Bool
    ) -> C.Index {
        var first = startIndex
        var count = collection.distance(from: first, to: endIndex)
        while count > 0 {
            let step = count / 2
            let it = collection.index(first, offsetBy: step)
            
            if (!compare(value, collection[it])) {
                first = collection.index(after: it)
                count -= step + 1
            } else {
                count = step
            }
        }
        return first
    }
    
    static func upper<C: BidirectionalCollection, T>(
        of value: T,
        in collection: C,
        comparedBy compare: (T, C.Element) -> Bool
    ) -> C.Index {
        return upper(
            of: value,
            in: collection,
            from: collection.startIndex,
            to: collection.endIndex,
            comparedBy: compare
        )
    }
    
    static func upper<C: BidirectionalCollection>(
        of value: C.Element,
        in collection: C,
        from startIndex: C.Index,
        to endIndex: C.Index
    ) -> C.Index where C.Element : Comparable {
        return upper(of: value, in: collection, from: startIndex, to: endIndex, comparedBy: <)
    }
    
    static func upper<C: BidirectionalCollection>(
        of value: C.Element,
        in collection: C
    ) -> C.Index where C.Element : Comparable {
        return upper(
            of: value,
            in: collection,
            from: collection.startIndex,
            to: collection.endIndex
        )
    }
}
