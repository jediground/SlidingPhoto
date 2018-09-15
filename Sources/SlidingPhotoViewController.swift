//
//  SlidingPhotoViewController.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class SlidingPhotoViewController: UIViewController {
    public let slidingPhotoView: SlidingPhotoView = SlidingPhotoView()

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        slidingPhotoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slidingPhotoView)
        slidingPhotoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        slidingPhotoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        slidingPhotoView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        slidingPhotoView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        slidingPhotoView.delegate = self
        slidingPhotoView.dataSource = self
    }
}

extension SlidingPhotoViewController: SlidingPhotoViewDataSource, SlidingPhotoViewDelegate {
    open func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int { return 0 }
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, loadContentsFor cell: SlidingPhotoViewCell) {}
    
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdatePageTo index: Int) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTappedAt location: CGPoint, in cell: SlidingPhotoViewCell) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didLongPressedAt location: CGPoint, in cell: SlidingPhotoViewCell) {}
    open func didDismiss(_ slidingPhotoView: SlidingPhotoView) {}
}
