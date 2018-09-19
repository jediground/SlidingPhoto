//
//  SlidingPhotoProtocols.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

public protocol SlidingPhotoDisplayable: class {
    var image: UIImage? { get set }
}

extension UIImageView: SlidingPhotoDisplayable {}

@objc public protocol SlidingPhotoViewDataSource {
    @objc func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int
    /// In one transcation may invoke this methods multiple times with same indexed cell.
    @objc func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, loadContentsFor cell: SlidingPhotoViewCell)
}

@objc public protocol SlidingPhotoViewDelegate {
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdatePageTo index: Int)
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTappedAt location: CGPoint, `in` cell: SlidingPhotoViewCell)
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didLongPressedAt location: CGPoint, `in` cell: SlidingPhotoViewCell)
}
