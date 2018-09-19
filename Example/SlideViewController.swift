//
//  SlideViewController.swift
//  Example
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit
import SlidingPhoto
import Kingfisher

class SlideViewController: SlidingPhotoViewController {
    private let vc: PhotosViewController
    private let data: [UIImage]
    private let fromPage: Int
    init(from vc: PhotosViewController, data: [UIImage], fromPage: Int) {
        self.vc = vc
        self.data = data
        self.fromPage = fromPage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        SlidingPhotoViewCell.displayViewClass = AnimatedImageView.self

        super.viewDidLoad()
        
        slidingPhotoView.register(CustomPhotoViewCell.self)
//        slidingPhotoView.register(NibPhotoCell.nib)
        slidingPhotoView.scrollToItem(at: fromPage, animated: false)
    }
    
    private lazy var statusBarWindow: UIView = UIApplication.shared.value(forKey: "statusBarWindow") as! UIView
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.25) {
            self.statusBarWindow.transform = CGAffineTransform(translationX: 0, y: -UIApplication.shared.statusBarFrame.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.25) {
            self.statusBarWindow.transform = .identity
        }
    }
    
    override func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int {
        return data.count
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, loadContentFor cell: SlidingPhotoViewCell) {
        let image = data[cell.index]
        if cell.image != image {
            cell.image = image
        }
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, thumbnailFor cell: SlidingPhotoViewCell) -> SlidingPhotoDisplayView? {
        return (vc.collectionView.cellForItem(at: IndexPath(item: cell.index, section: 0)) as? PhotoCollectionViewCell)?.imageView
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTappedAt location: CGPoint, in cell: SlidingPhotoViewCell) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
