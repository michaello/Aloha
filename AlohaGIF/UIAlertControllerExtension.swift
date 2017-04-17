//
//  UIAlertControllerExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func showTooLongVideoAlert() {
        let alert = UIAlertController(title: "Video is too long", message: "Sorry, currently we are supporting videos that are shorter than \(Int(maximumMovieLength)) seconds. You can go to Photos and adjust length of the video manually.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
    }
}

