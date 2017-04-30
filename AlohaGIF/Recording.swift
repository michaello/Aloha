//
//  Recording.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 22/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation

struct Recording {
    private var startDate = Date()
    private var cachedEndTime: TimeInterval?
    
    mutating func start() {
        cachedEndTime = nil
        startDate = Date()
    }
    
    mutating func end() -> TimeInterval {
        if cachedEndTime == nil {
            cachedEndTime = (Date().timeIntervalSince1970 - startDate.timeIntervalSince1970).roundedTo(places: 2)
            return cachedEndTime ?? 0.0
        } else {
            return cachedEndTime ?? 0.0
        }
    }
}

private extension Double {
    func roundedTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
