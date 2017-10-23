//
//  AnimationModel.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation

struct AnimationModel {
    let beginTime: TimeInterval
    let duration: TimeInterval
    var finishTime: TimeInterval {
        return beginTime + duration
    }
}
