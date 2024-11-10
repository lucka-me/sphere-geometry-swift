//
//  Earth.swift
//
//
//  Created by Lucka on 18/8/2024.
//

import Foundation

public struct Earth {
    private init() { }
}

public extension Earth {
    static let radius: Double = 6371010
    static let area: Double = radius * radius * 4 * .pi
}
