//
//  VideoToolbarViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 22/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

enum VideoOptionMenu: Int {
    case effects
    case fonts
    case colors
    case complete
}

protocol VideoToolbarViewControllerDelegate: class {
    func willEnterToVideoOptionMenu(videoOptionMenu: VideoOptionMenu)
}

class VideoToolbarViewController: UIViewController {

    @IBOutlet weak var stackView: UIStackView!
    var isCollapsed = false
    weak var delegate: VideoToolbarViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.arrangedSubviews
            .flatMap { $0 as? UIButton }
            .forEach { $0.addTarget(self, action: #selector(VideoToolbarViewController.menuOptionButtonAction(_:)), for: .touchUpInside) }
        
    }
    
    @objc private func menuOptionButtonAction(_ sender: UIButton) {
        if let index = stackView.arrangedSubviews.index(of: sender), let videoOptionMenu = VideoOptionMenu(rawValue: index) {
            delegate?.willEnterToVideoOptionMenu(videoOptionMenu: videoOptionMenu)
        }
    }
}
