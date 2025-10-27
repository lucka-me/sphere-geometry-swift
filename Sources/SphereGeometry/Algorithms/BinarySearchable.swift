//
//  BinarySearchable.swift
//  SphereGeometry
//
//  Created by Lucka on 12/9/2024.
//

import Foundation

public protocol BinarySearchable : BidirectionalCollection {
    
}

public extension BinarySearchable {
    func lower<T>(
        of value: T,
        from startIndex: Index,
        to endIndex: Index,
        comparedBy compare: (Element, T) -> Bool
    ) -> Index {
        var first = startIndex
        var count = distance(from: first, to: endIndex)
        while count > 0 {
            let step = count / 2
            let it = index(first, offsetBy: step)
            if (compare(self[it], value)) {
                first = index(after: it)
                count -= step + 1
            } else {
                count = step
            }
        }
        return first
    }
    
    func lower<T>(of value: T, comparedBy compare: (Element, T) -> Bool) -> Index {
        return lower(of: value, from: startIndex, to: endIndex, comparedBy: compare)
    }
    
    func upper<T>(
        of value: T,
        from startIndex: Index,
        to endIndex: Index,
        comparedBy compare: (T, Element) -> Bool
    ) -> Index {
        var first = startIndex
        var count = distance(from: first, to: endIndex)
        while count > 0 {
            let step = count / 2
            let it = index(first, offsetBy: step)
            
            if (!compare(value, self[it])) {
                first = index(after: it)
                count -= step + 1
            } else {
                count = step
            }
        }
        return first
    }
    
    func upper<T>(of value: T, comparedBy compare: (T, Element) -> Bool) -> Index {
        return upper(of: value, from: startIndex, to: endIndex, comparedBy: compare)
    }
}

public extension BinarySearchable where Element: Comparable {
    func lower(of value: Element, from startIndex: Index, to endIndex: Index) -> Index {
        return lower(of: value, from: startIndex, to: endIndex) { $0 < $1 }
    }
    
    func lower(of value: Element) -> Index {
        return lower(of: value, from: startIndex, to: endIndex)
    }
    
    func upper(of value: Element, from startIndex: Index, to endIndex: Index) -> Index {
        return upper(of: value, from: startIndex, to: endIndex) { $0 < $1 }
    }
    
    func upper(of value: Element) -> Index {
        return upper(of: value, from: startIndex, to: endIndex)
    }
}
