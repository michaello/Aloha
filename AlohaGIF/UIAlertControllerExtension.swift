//
//  UIAlertControllerExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

enum AlertErrorReason {
    case tooLongVideo(limit: Int)
    case speechNotDetected
    
    var content: (title: String, message: String) {
        switch self {
        case .tooLongVideo(let limit):
            return ("Video is too long", "Sorry, currently we are supporting videos that are shorter than \(limit) seconds. You can go to Photos and adjust length of the video manually.")
        case .speechNotDetected:
            return ("Whoops!", "Sorry, we couldn't detect speech in this video. Please try again or choose different video.")
        }
    }
}

extension UIAlertController {
    
    private static var topViewController: UIViewController? {
        //Ugly, but works
        var topViewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
        topViewController = topViewController?.presentedViewController ?? topViewController ?? UIApplication.shared.keyWindow?.rootViewController
        
        return topViewController
    }
    
    static func show(_ reason: AlertErrorReason) {
        let alert = UIAlertController(title: reason.content.title, message: reason.content.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIAlertController.topViewController?.present(alert, animated: true)
    }
}

