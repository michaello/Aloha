//
//  ALLoadingViewExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 27/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

extension ALLoadingView {
    static func show() {
        ALLoadingView.manager.blurredBackground = true
        ALLoadingView.manager.messageText = PropertyList.randomText(type: .loading)
        ALLoadingView.manager.showLoadingView(ofType: .messageWithIndicator, windowMode: .fullscreen)
    }
}
