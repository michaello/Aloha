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
        return propertyList(forResource: Constants.swiftyBeaverTokensPlistName, withExtension: Constants.plistExtension) as? [String: Any]
    }
    
    static func randomText(type: ListType) -> String {
        if let randomTextsArray = propertyList(forResource: type.rawValue, withExtension: Constants.plistExtension) as? [String] {
            return randomTextsArray.randomItem
        } else {
            return Constants.defaultRandomText
        }
    }
    
    private static func propertyList(forResource resource: String, withExtension extensionString: String) -> Any? {
        if let fileUrl = Bundle.main.url(forResource: resource, withExtension: extensionString), let data = try? Data(contentsOf: fileUrl), let propertyListRaw = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
            return propertyListRaw
        } else {
            return nil
        }
    }
}

private extension Array {

    var randomItem: Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
