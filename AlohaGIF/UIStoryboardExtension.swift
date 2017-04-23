//
//  UIStoryboardExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIStoryboard {
    func viewController(forVideoOptionMenu videoOptionMenu: VideoOptionMenu) -> UIViewController? {
        switch videoOptionMenu {
        case .effects:
            return instantiateViewController(withIdentifier: String(describing: EffectsViewController.self)) as! EffectsViewController
        case .fonts:
            return instantiateViewController(withIdentifier: String(describing: FontsViewController.self)) as! FontsViewController
        case .colors:
            return instantiateViewController(withIdentifier: String(describing: ColorsViewController.self)) as! ColorsViewController
        case .complete: return nil
        }
    }
}
