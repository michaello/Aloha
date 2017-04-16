//
//  CardOnboardingViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 15/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class CardOnboardingViewController: UIViewController {

    @IBOutlet weak var cardView: CardView!
    @IBOutlet weak var permissionsLabel: UILabel!
    //TODO: Make as UIButton later
    @IBOutlet weak var allowPermissionsImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CardOnboardingViewController.allowPermissionsImageViewAction(sender:)))
        allowPermissionsImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func allowPermissionsImageViewAction(sender: UITapGestureRecognizer) {
        print("Action")
    }
}
