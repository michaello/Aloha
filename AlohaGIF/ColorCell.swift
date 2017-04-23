//
//  ColorCell.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class ColorCell: UICollectionViewCell {
    private var internalColor: UIColor?
    var color: UIColor {
        get { return internalColor ?? backgroundColor ?? .white }
        set {
            internalColor = newValue
            backgroundColor = internalColor
        }
    }
}
