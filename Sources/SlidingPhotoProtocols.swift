//
//  SlidingPhotoProtocols.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

@objc public protocol SlidingPhotoDisplayable: class {
    var image: UIImage? { get set }
}

public typealias SlidingPhotoDisplayView = UIView & SlidingPhotoDisplayable

extension UIImageView: SlidingPhotoDisplayable {}

@objc public protocol SlidingPhotoViewDataSource: NSObjectProtocol {
    @objc func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int
    /// In one transcation may invoke this methods multiple times with same indexed cell.
    @objc func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, prepareForDisplay cell: SlidingPhotoViewCell)
    /// Thumbnail for present animation.
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, thumbnailFor cell: SlidingPhotoViewCell) -> SlidingPhotoDisplayView?
}

@objc public protocol SlidingPhotoViewDelegate: NSObjectProtocol {
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdateFocus cell: SlidingPhotoViewCell)
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didEndDisplaying cell: SlidingPhotoViewCell)
    
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTappedAt location: CGPoint, `in` cell: SlidingPhotoViewCell)
    @objc optional func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didLongPressedAt location: CGPoint, `in` cell: SlidingPhotoViewCell)
}
