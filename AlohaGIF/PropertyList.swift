//
//  PropertyList.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 30/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation

enum ListType: String {
    case loading = "LoadingTexts"
    case shortRecording = "ShortRecordingNoticeTexts"
}

struct PropertyList {
    static func randomText(type: ListType) -> String {
        if let fileUrl = Bundle.main.url(forResource: type.rawValue, withExtension: "plist"), let data = try? Data(contentsOf: fileUrl), let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
            return result?.randomItem ?? "Loading..."
        } else {
            return ""
        }
    }
}

fileprivate extension Array {
    var randomItem: Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
