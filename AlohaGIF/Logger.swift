//
//  Logger.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import SwiftyBeaver

struct Logger {
    static func info(_ logMessage: String) {
        SwiftyBeaver.info(logMessage)
    }
    
    static func debug(_ logMessage: String) {
        SwiftyBeaver.debug(logMessage)
    }
    
    static func verbose(_ logMessage: String) {
        SwiftyBeaver.verbose(logMessage)
    }
    
    static func error(_ logMessage: String) {
        SwiftyBeaver.error(logMessage)
    }
}
