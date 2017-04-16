//
//  CardView.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class CardView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    private func setupLayout() {
        backgroundColor = .white
        layer.cornerRadius = 8.0
        layer.shadowOpacity = 0.4
        layer.shadowColor = UIColor.black.cgColor
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
    }
}
