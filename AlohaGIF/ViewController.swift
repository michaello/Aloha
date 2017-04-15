//
//  ViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 15/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = view.subviews.flatMap { $0 as? UIImageView }.first!
        imageView.layer.masksToBounds = true
//        imageView.layer.cornerRadius = 90.0
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

