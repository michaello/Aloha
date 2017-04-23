//
//  ColorsViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

class ColorsViewController: UIViewController {
    
    let colors = [UIColor.black, UIColor.white, #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1), #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1), #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1), #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1) ,#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)]
    @IBOutlet weak var collectionView: UICollectionView!
    var selectedCellIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: 60.0, height: 60.0)
    }
}

extension ColorsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectedCellIndexPath != indexPath else { return }
        let previousIndexPath = selectedCellIndexPath
        selectedCellIndexPath = indexPath
        collectionView.reloadItems(at: [previousIndexPath, indexPath].flatMap { $0 })
    }
}

extension ColorsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ColorCell.self), for: indexPath) as! ColorCell
        cell.layer.cornerRadius = cell.frame.width / 2
        cell.backgroundColor = colors[indexPath.row]
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.7
        cell.layer.shadowRadius = 5.0
        if let selectedCellIndexPath = selectedCellIndexPath, indexPath == selectedCellIndexPath {
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColor.white.cgColor
        } else {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        
        return cell
    }
}
