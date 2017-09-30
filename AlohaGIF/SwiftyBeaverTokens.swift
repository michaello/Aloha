//
//  SwiftyBeaverTokens.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 30/09/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

struct SwiftyBeaverTokens {
    
    private enum Constants {
        static let appID = "appID"
        static let encryptionKey = "encryptionKey"
        static let appSecret = "appSecret"
    }
    
    let appID: String
    let appSecret: String
    let encryptionKey: String
    
    init?(dictionary: [String: Any]?) {
        guard let dictionary = dictionary else { return nil }
        self.appID = dictionary[Constants.appID] as? String ?? ""
        self.encryptionKey = dictionary[Constants.encryptionKey] as? String ?? ""
        self.appSecret = dictionary[Constants.appSecret] as? String ?? ""
    }
}
