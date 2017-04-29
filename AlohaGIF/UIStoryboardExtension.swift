//
//  UIStoryboardExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

fileprivate enum Storyboard: String {
    case main = "Main"
}


extension UIStoryboard {
    func viewController(forVideoOptionMenu videoOptionMenu: VideoOptionMenu, dynamicSubtitlesStyle: DynamicSubtitlesStyle = DynamicSubtitlesStyle.default) -> DynamicSubtitlesModifyingViewController? {
        switch videoOptionMenu {
        case .effects:
            let viewController = UIStoryboard.viewController(EffectsViewController.self)
            viewController.selectedEffect = dynamicSubtitlesStyle.effect
            return viewController
        case .fonts:
            let viewController = UIStoryboard.viewController(FontsViewController.self)
            viewController.selectedFont = dynamicSubtitlesStyle.font
            return viewController
        case .colors:
            let viewController = UIStoryboard.viewController(ColorsViewController.self)
            viewController.selectedColor = dynamicSubtitlesStyle.color
            return viewController
        case .complete: return nil
        }
    }
    
    static func viewController<T: UIViewController>(_ type: T.Type) -> T {
        let storyboard = UIStoryboard(name: Storyboard.main.rawValue, bundle: nil)
        
        return storyboard.instantiateViewController(withIdentifier: String(describing: T.self)) as! T
    }
}
