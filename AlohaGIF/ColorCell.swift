//
//  ColorCell.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class ColorCell: UICollectionViewCell {
    
    private enum Constants {
        static let halfSize: CGFloat = 30.0
    }
    
    var isMarked: Bool = false {
        didSet {
            layer.borderWidth = isMarked ? 4.0 : 0.0
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = Constants.halfSize
    }
}
