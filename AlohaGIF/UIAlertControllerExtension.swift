//
//  UIAlertControllerExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    private static var topViewController: UIViewController? {
        //Ugly, but works
        var topViewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
        topViewController = topViewController?.presentedViewController ?? topViewController ?? UIApplication.shared.keyWindow?.rootViewController
        
        return topViewController
    }
    
    static func showTooLongVideoAlert() {
        let alert = UIAlertController(title: "Video is too long", message: "Sorry, currently we are supporting videos that are shorter than \(Int(maximumMovieLength)) seconds. You can go to Photos and adjust length of the video manually.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIAlertController.topViewController?.present(alert, animated: true, completion: nil)
    }
    
    static func showSpeechNotDetectedAlert() {
        let alert = UIAlertController(title: "Whoops!", message: "Sorry, we couldn't detect speech in this video. Please try again or choose different video.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIAlertController.topViewController?.present(alert, animated: true, completion: nil)
    }
}

