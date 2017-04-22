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
    private var endDate: Date?
    
    mutating func start() {
        startDate = Date()
    }
    
    mutating func end() -> TimeInterval {
        let endDateNotNil = self.endDate ?? Date()
        
        return endDateNotNil.timeIntervalSince1970 - startDate.timeIntervalSince1970
    }
}
