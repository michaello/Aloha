//
//  EffectsViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

class EffectsViewController: UIViewController {
    
    @IBOutlet weak var oneAfterAnotherButton: UIButton!
    @IBOutlet weak var oneWordOnlyButton: UIButton!
    @IBOutlet weak var selectedEffectHighlightView: UIView!
    private(set) var selectedSubtitlesEffect: DynamicSubtitlesType = .oneAfterAnother

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedEffectHighlightView.frame = CGRect(x: oneWordOnlyButton.frame.origin.x, y: oneWordOnlyButton.frame.origin.y + oneWordOnlyButton.frame.size.height * 2, width: oneWordOnlyButton.frame.size.width, height: 3.0)
        selectedEffectHighlightView.backgroundColor = .white
    }
    
    @IBAction func effectButtonAction(_ sender: UIButton) {
        if sender == oneAfterAnotherButton {
            selectedSubtitlesEffect = .oneAfterAnother
            print("One after another")
        } else {
            selectedSubtitlesEffect = .oneWordOnly
            print("One word only")
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            let length = sender.frame.size.width / 2
            self.selectedEffectHighlightView.frame = CGRect(x: sender.center.x - length / 2, y: sender.frame.origin.y + sender.frame.size.height * 2, width: length, height: 3.0)
        }, completion: nil)
    }
}
