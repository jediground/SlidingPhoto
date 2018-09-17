//
//  UIImageView+SlidingPhoto.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/17/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

public final class SlidingPhoto<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol SlidingPhotoCompatible {
    associatedtype CompatibleType
    var sp: CompatibleType { get }
}

public extension SlidingPhotoCompatible {
    public var sp: SlidingPhoto<Self> {
        return SlidingPhoto(self)
    }
}

public extension SlidingPhoto where Base: UIView {
    public var image: UIImage? {
        get {
            if let imageView = base as? SlidingPhotoDisplayable {
                return imageView.image
            } else {
                let contents = base.layer.contents
                if nil == contents {
                    return nil
                } else {
                    return UIImage(cgImage: contents as! CGImage)
                }
            }
        }
        set {
            let current = CACurrentMediaTime()

            if let imageView = base as? SlidingPhotoDisplayable {
                imageView.image = newValue
            } else {
                base.layer.contents = newValue?.cgImage
            }
            
            if let image = newValue {
                let iw = image.size.width
                let ih = image.size.height
                let vw = base.bounds.width
                let vh = base.bounds.height
                let scale = (ih / iw) / (vh / vw)
                if !scale.isNaN && scale > 1.0 {
                    // image: h > w
                    base.contentMode = .scaleToFill
                    base.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: (iw / ih) * (vh / vw))
                } else {
                    // image: w > h
                    base.contentMode = .scaleAspectFill
                    base.layer.contentsRect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
                }
            }
            
            if CACurrentMediaTime() - current > 0.2 {
                base.layer.add(CATransition(), forKey: kCATransition)
            }
        }
    }
}

extension UIView: SlidingPhotoCompatible {}
