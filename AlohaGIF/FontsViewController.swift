//
//  FontsViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

class FontsViewController: UIViewController {
    
    private struct Constants {
        static let fontSize: CGFloat = 22.0
        static let fontsNames = [
            "Copperplate-Bold",
            "CourierNewPS-BoldMT",
            "GillSans-Bold",
            "AppleSDGothicNeo-Bold",
            "AvenirNextCondensed-Bold",
            "TamilSangamMN-Bold",
            "HelveticaNeue-CondensedBold",
            "Georgia-Bold",
            "ArialRoundedMTBold",
            "ChalkboardSE-Bold",
            "Futura-CondensedExtraBold",
            "Futura-Bold"
        ]
        static let fonts = Constants.fontsNames.flatMap { UIFont.init(name: $0, size: Constants.fontSize) } + [UIFont.boldSystemFont(ofSize: Constants.fontSize)]
    }

    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate let fonts = Constants.fonts
    fileprivate(set) var selectedFont = UIFont.boldSystemFont(ofSize: 16.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = CGSize(width: 100, height: 100)
    }
}

extension FontsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! FontCell
        selectedFont = cell.fontLabel.font
    }
}

extension FontsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fonts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FontCell.self), for: indexPath) as! FontCell
        cell.fontLabel.attributedText = NSAttributedString.init(string: "Lorem ipsum", attributes: DynamicSubtitlesType.oneWordOnly.textAttributes)
        cell.fontLabel.font = fonts[indexPath.row]
        
        return cell
    }
}

