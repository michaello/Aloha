//
//  UIColorExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIColor {
    static let themeColor = #colorLiteral(red: 0.9921568627, green: 0.4980392157, blue: 0.3254901961, alpha: 1)
    
    static func themeColorForPermissionPageControl(withPosition position: Double) -> UIColor {
        let diff = 2.5 - Float(position)

        return UIColor(colorLiteralRed: 253.0/255.0, green: 127.0/255.0, blue: 83.0/255.0, alpha: diff)
    }
}
