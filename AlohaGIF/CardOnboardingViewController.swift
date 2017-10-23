//
//  CardOnboardingViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 15/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class CardOnboardingViewController: UIViewController {

    @IBOutlet private(set) weak var cardView: CardView!
    @IBOutlet private(set) weak var permissionsLabel: UILabel! {
        didSet { permissionsLabel.text = Constants.onboardingText }
    }
    @IBOutlet private weak var allowPermissionsButton: UIButton!
    private let permissionController = PermissionController()
    
    private enum Constants {
        static let onboardingText = "We need to ask you for permissions:\n\n📷 Camera - for recording your short videos.\n\n🎞 Video Library - for choosing short videos from your iPhone.\n\n🎙 Microphone - for recording audio with your videos.\n\n🙊 Speech Recognition - for embedding dynamic subtitles to your GIF!"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardView.setupLayout()
    }
    
    @IBAction func allowPermissionsButtonAction(sender: UIButton) {
        UserDefaults.standard.userPassedOnboarding()
        permissionController.requestForAllPermissions { permissionSet in
            DispatchQueue.main.async {
                UIApplication.shared.keyWindow?.rootViewController = UIStoryboard.viewController(CameraViewController.self)
            }
        }
    }
}
