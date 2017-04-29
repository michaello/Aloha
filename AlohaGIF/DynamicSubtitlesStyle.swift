//
//  DynamicSubtitlesStyle.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 24/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

struct DynamicSubtitlesStyle {
    static let `default` = DynamicSubtitlesStyle(effect: DynamicSubtitlesType.oneAfterAnother, font: UIFont.boldSystemFont(ofSize: 16.0), color: .white)
    let effect: DynamicSubtitlesType
    let font: UIFont
    let color: UIColor
    
    func font(forRenderingVideo logicValue: Bool) -> UIFont {
        var multiplier = effect == .oneAfterAnother ? 6.0 : 12.0
        multiplier = logicValue ? (multiplier * 1.5) : (multiplier / Double(aScale))
        let fontSize: CGFloat = 4.0 * CGFloat(multiplier)
        
        return font.withSize(fontSize)
    }
    
    var textAttributes: [String : Any] {
        return [
            NSStrokeWidthAttributeName : -2.0,
            NSStrokeColorAttributeName : UIColor.black,
            NSFontAttributeName : font(forRenderingVideo: isRenderingVideo),
            NSForegroundColorAttributeName : color
        ]
    }
}
