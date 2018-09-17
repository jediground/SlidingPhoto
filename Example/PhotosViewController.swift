//
//  PhotosViewController.swift
//  Example
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit
import Kingfisher

private let reuseIdentifier = "PhotoCell"

class PhotosViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private lazy var data: [UIImage] = {
        let bundlePath = Bundle(for: type(of: self)).path(forResource: "Images", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        let paths = (0...10).map({ bundle.path(forResource: "image-\($0)", ofType: "jpg")! })
        let bins = paths.map({ try! Data(contentsOf: URL(fileURLWithPath: $0)) })
        let images = bins.map({ Kingfisher<Image>.image(data: $0, scale: 1, preloadAllAnimationData: true, onlyFirstFrame: false) })
        return images.compactMap({ $0 })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.sp.image = data[indexPath.item]
        cell.layer.borderColor = UIColor.cyan.cgColor
        cell.layer.borderWidth = 1
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = floor((collectionView.bounds.width - 24) / 2.0)
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = SlideViewController(data: data, fromPage: indexPath.item)
        present(vc, animated: true, completion: nil)
    }
}

// MARK: - PhotoCollectionViewCell

final class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
