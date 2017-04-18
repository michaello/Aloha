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

        return true
    }
    
    private func setupLogging() {
        let console = ConsoleDestination()
        SwiftyBeaver.addDestination(console)
        let platform = SBPlatformDestination(appID: "AOBNLa",
                                             appSecret: "Pfrrne3jiDXbFhnRqsvjK7krUmahg3hq",
                                             encryptionKey: "y5wkyx3waMg9rlhKm8zxztydhssrp4ai")
        SwiftyBeaver.addDestination(platform)
    }
}

