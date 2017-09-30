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
    
    private enum Constants {
        static let plistExtension = "plist"
        static let defaultRandomText = "Loading..."
        static let swiftyBeaverTokensPlistName = "SwiftyBeaverTokens"
    }
    
    static var swiftyBeaverTokensPropertyList: [String: Any]? {
        if let fileUrl = Bundle.main.url(forResource: Constants.swiftyBeaverTokensPlistName, withExtension: Constants.plistExtension), let data = try? Data(contentsOf: fileUrl), let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            return result
        } else {
            return nil
        }
    }
    
    static func randomText(type: ListType) -> String {
        if let fileUrl = Bundle.main.url(forResource: type.rawValue, withExtension: Constants.plistExtension), let data = try? Data(contentsOf: fileUrl), let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
            return result?.randomItem ?? Constants.defaultRandomText
        } else {
            return ""
        }
    }
}

private extension Array {

    var randomItem: Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
