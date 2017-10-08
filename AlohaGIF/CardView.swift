//
//  CardView.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class CardView: UIView {
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
        static let shadowOpacity: Float = 0.3
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupLayout() {
        backgroundColor = .white
        layer.cornerRadius = Constants.cornerRadius
        setupShadow()
    }
    
    private func setupShadow() {
        let path = UIBezierPath()
        let xOffset: CGFloat = 1.0
        let yOffset: CGFloat = 4.0
        path.move(to: CGPoint(x: xOffset, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width - xOffset, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width - xOffset, y: yOffset))
        path.addLine(to: CGPoint(x: xOffset, y: yOffset))
        path.close()
        layer.shadowPath = path.cgPath
        layer.shadowOpacity = Constants.shadowOpacity
        layer.shadowColor = UIColor.black.cgColor
    }
}
