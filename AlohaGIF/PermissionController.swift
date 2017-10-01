//
//  PermissionController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Permission

struct PermissionController {
    
    private enum Constants {
        static let permissions: [Permission] = [.camera, .microphone, .speechRecognizer]
    }
    
    func requestForAllPermissions(completion: @escaping (PermissionSet) -> ()) {
        Promise<PermissionStatus>.all(permissionPromises()).then { _ in
            completion(PermissionSet(Constants.permissions))
        }
    }
    
    private func permissionPromises() -> [Promise<PermissionStatus>] {        
        return Constants.permissions.map { permission in
            Promise<(PermissionStatus)>(work: { fulfill, _ in
                permission.request { status in
                    if case .authorized = status {
                        fulfill(status)
                    }
                }
            })
        }
    }
}
