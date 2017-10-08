//
//  FontsViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

protocol ScrollableCollectionViewController: class {
    var selectedIndexPath: IndexPath? { get set }
    weak var collectionView: UICollectionView! { get }
    func scrollToSelectedFontIfNeeded()
}

extension ScrollableCollectionViewController {
    //Hack with GCD to make it work
    func scrollToSelectedFontIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.001) {
            if let selectedIndexPath = self.selectedIndexPath {
                self.collectionView.scrollToItem(at: selectedIndexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
            }
        }
    }
}

final class FontsViewController: DynamicSubtitlesModifyingViewController, ScrollableCollectionViewController {
    
    fileprivate struct Constants {
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
        static let fonts = [UIFont.boldSystemFont(ofSize: Constants.fontSize)] + Constants.fontsNames.flatMap { UIFont(name: $0, size: Constants.fontSize) }
        static let placeholderText = "Lorem Ipsum"
    }

    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate let fonts = Constants.fonts
    var selectedIndexPath: IndexPath?
    var selectedFont = UIFont.boldSystemFont(ofSize: 16.0) {
        didSet {
            Logger.info("User selected font: \(selectedFont.description)")
            if let selectedFontIndex = fonts.index(of: selectedFont) {
                selectedIndexPath = IndexPath(row: selectedFontIndex, section: 0)
                handler?.handle(.font(selectedFont))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.indicatorStyle = .white
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        scrollToSelectedFontIfNeeded()
    }
}

extension FontsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectedIndexPath != indexPath else { return }
        selectedIndexPath = indexPath
        selectedFont = fonts[indexPath.row]
        //Why not reloadItems(at:) like in Colors? Looks like estimated size for cell messes this method up.

        collectionView.reloadData()
    }
}

extension FontsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fonts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FontCell.self), for: indexPath) as! FontCell
        cell.attributedText = NSAttributedString(string: Constants.placeholderText, attributes: DynamicSubtitlesStyle.default.textAttributes)
        cell.font = fonts[indexPath.row]
        if let selectedIndexPath = selectedIndexPath, indexPath == selectedIndexPath {
            cell.mark(isSelected: true)
        }
        
        return cell
    }
}

