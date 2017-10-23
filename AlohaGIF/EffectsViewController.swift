//
//  EffectsViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

protocol ModifiedDynamicSubtitlesHandler: class {
    func handle(_ modification: DynamicSubtitlesModification)
}

final class EffectsViewController: DynamicSubtitlesModifyingViewController {
    
    private enum Constants {
        static let highlightViewYOffset: CGFloat = -30.0
        static let highlightViewHeight: CGFloat = 3.0
    }
    
    @IBOutlet private weak var oneAfterAnotherButton: UIButton!
    @IBOutlet private weak var oneWordOnlyButton: UIButton!
    @IBOutlet private weak var selectedEffectHighlightView: UIView!
    var selectedEffect: DynamicSubtitlesType = .oneAfterAnother {
        didSet {
            handler?.handle(.effect(selectedEffect))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        selectedEffectHighlightView.backgroundColor = .themeColor
        let effectButton = button(for: selectedEffect)
        let length = effectButton.frame.size.width / 2.0
        selectedEffectHighlightView.frame = CGRect(x: effectButton.center.x - length / 4.0, y: view.frame.height + Constants.highlightViewYOffset, width: length, height: Constants.highlightViewHeight)
    }
    
    @IBAction func effectButtonAction(_ sender: UIButton) {
        if sender == oneAfterAnotherButton {
            selectedEffect = .oneAfterAnother
            Logger.verbose("User selected effect: oneAfterAnotherButton")
        } else {
            selectedEffect = .oneWordOnly
            Logger.verbose("User selected effect: oneWordOnly")
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            let length = sender.frame.size.width / 2.0
            self.selectedEffectHighlightView.frame = CGRect(x: sender.center.x - length / 4.0, y: self.view.frame.height + Constants.highlightViewYOffset, width: length, height: Constants.highlightViewHeight)
        }, completion: nil)
    }
    
    private func button(for type: DynamicSubtitlesType) -> UIButton {
        if case .oneAfterAnother = type {
            return oneAfterAnotherButton
        } else {
            return oneWordOnlyButton
        }
    }
}
