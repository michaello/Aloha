//
//  FontCell.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class FontCell: UICollectionViewCell {

    var font: UIFont {
        get { return fontLabel.font }
        set { fontLabel.font = newValue }
    }
    var attributedText: NSAttributedString {
        get { return fontLabel.attributedText ?? NSAttributedString() }
        set { fontLabel.attributedText = newValue }
    }
    @IBOutlet private weak var fontLabel: UILabel!
    @IBOutlet private weak var highlightView: UIView! {
        didSet {
            highlightView.backgroundColor = .themeColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        highlightView.alpha = 0.0
    }
    
    func mark(isSelected: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.highlightView.alpha = isSelected ? 1.0 : 0.0
        }
    }
    
    private func setHighlightView() {
        highlightView.backgroundColor = .themeColor
    }
}
