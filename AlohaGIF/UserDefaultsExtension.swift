//
//  UserDefaultsExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 27/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation

fileprivate let isOnboardingCompletedSubscript = "isOnboardingCompleted"

extension UserDefaults {
    var isOnboardingCompleted: Bool {
        return self[isOnboardingCompletedSubscript] as? Bool ?? false
    }
    
    func userPassedOnboarding() {
        self[isOnboardingCompletedSubscript] = true
    }
    
    subscript(key: String) -> Any? {
        get {
            return object(forKey: key)
        } set {
            set(newValue, forKey: key)
            synchronize()
        }
    }
}
