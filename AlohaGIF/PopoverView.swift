//
//  PopoverView.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 30/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import Popover

final class PopoverView: UIView {
    
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = PropertyList.randomText(type: .shortRecording)
        }
    }
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    func show(from view: UIView) {
        let options: [PopoverOption] = [.type(.up), .dismissOnPopover, .showBlackOverlay(true)]
        let popover = Popover(options: options, showHandler: nil, dismissHandler: nil)
        popover.show(self, fromView: view)
    }
}
