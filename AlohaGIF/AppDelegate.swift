//
//  AppDelegate.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 15/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import SwiftyBeaver

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setupLogging()
        window?.rootViewController = startingViewController()
        
        return true
    }
    
    private func startingViewController() -> UIViewController {
        if UserDefaults.standard.isOnboardingCompleted {
            return UIStoryboard.viewController(CameraViewController.self)
        } else {
            return UIStoryboard.viewController(OnboardingViewController.self)
        }
    }
    
    private func setupLogging() {
        let console = ConsoleDestination()
        SwiftyBeaver.addDestination(console)
        setupPlatformLogging()
    }
    
    private func setupPlatformLogging() {
        guard let swiftyBeaverTokens = SwiftyBeaverTokens(dictionary: PropertyList.swiftyBeaverTokensPropertyList) else { return }
        let platform = SBPlatformDestination(appID: swiftyBeaverTokens.appID,
                                             appSecret: swiftyBeaverTokens.appSecret,
                                             encryptionKey: swiftyBeaverTokens.encryptionKey)
        SwiftyBeaver.addDestination(platform)
    }
}

