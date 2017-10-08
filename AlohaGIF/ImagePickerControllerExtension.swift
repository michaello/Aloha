//
//  ImagePickerControllerExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 08/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

extension ImagePickerController {
    static func defaultController(delegate: ImagePickerDelegate?) -> ImagePickerController {
        var config = Configuration()
        config.doneButtonTitle = "Finish"
        config.noImagesTitle = "Sorry! There are no images here!"
        
        let imagePicker = ImagePickerController()
        imagePicker.view.backgroundColor = .clear
        imagePicker.modalPresentationStyle = .overCurrentContext
        
        imagePicker.configuration = config
        imagePicker.delegate = delegate
        
        return imagePicker
    }
}
