//
//  UIDeviceExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 13/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIDevice {
    static var isNotSimulator: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil
    }
}
