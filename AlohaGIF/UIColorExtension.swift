//
//  UIColorExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIColor {
    static let themeColor = #colorLiteral(red: 0.9098039216, green: 0.537254902, blue: 0.3843137255, alpha: 1)
    
    static func themeColorForPermissionPageControl(withPosition position: Double) -> UIColor {
        let diff = 2.5 - Float(position)

        return UIColor(colorLiteralRed: 232/255.0, green: 137/255.0, blue: 98/255.0, alpha: diff)
    }
}
