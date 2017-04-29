//
//  ALLoadingViewExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 27/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation

extension ALLoadingView {
    
    static var randomLoadingText: String {
        if let fileUrl = Bundle.main.url(forResource: "LoadingTexts", withExtension: "plist"), let data = try? Data(contentsOf: fileUrl), let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
                return result?.randomItem ?? "Loading..."
        } else {
            return "Loading..."
        }
    }
    
    static func show() {
        ALLoadingView.manager.blurredBackground = true
        ALLoadingView.manager.messageText = ALLoadingView.randomLoadingText
        ALLoadingView.manager.showLoadingView(ofType: .messageWithIndicator, windowMode: .fullscreen)
    }
}

fileprivate extension Array {
    var randomItem: Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
