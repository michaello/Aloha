//
//  DynamicSubtitlesModifyingViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

enum DynamicSubtitlesModification {
    case effect(DynamicSubtitlesType)
    case color(UIColor)
    case font(UIFont)
}

class DynamicSubtitlesModifyingViewController: UIViewController {
    weak var handler: ModifiedDynamicSubtitlesHandler?
}
