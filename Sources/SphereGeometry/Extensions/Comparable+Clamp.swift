//
//  Comparable+Clamp.swift
//
//
//  Created by Lucka on 16/8/2024.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
