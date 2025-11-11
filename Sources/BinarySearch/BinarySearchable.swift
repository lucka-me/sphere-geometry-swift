//
//  BinarySearchable.swift
//  BinarySearch
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
        BinarySearch.lower(
            of: value,
            in: self,
            from: startIndex,
            to: endIndex,
            comparedBy: compare
        )
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
        BinarySearch.upper(
            of: value,
            in: self,
            from: startIndex,
            to: endIndex,
            comparedBy: compare
        )
    }
    
    func upper<T>(of value: T, comparedBy compare: (T, Element) -> Bool) -> Index {
        return upper(of: value, from: startIndex, to: endIndex, comparedBy: compare)
    }
}

public extension BinarySearchable where Element : Comparable {
    func lower(of value: Element, from startIndex: Index, to endIndex: Index) -> Index {
        return lower(of: value, from: startIndex, to: endIndex, comparedBy: <)
    }
    
    func lower(of value: Element) -> Index {
        return lower(of: value, from: startIndex, to: endIndex)
    }
    
    func upper(of value: Element, from startIndex: Index, to endIndex: Index) -> Index {
        return upper(of: value, from: startIndex, to: endIndex, comparedBy: <)
    }
    
    func upper(of value: Element) -> Index {
        return upper(of: value, from: startIndex, to: endIndex)
    }
}
