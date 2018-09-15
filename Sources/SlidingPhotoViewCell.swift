//
//  SlidingPhotoViewCell.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class SlidingPhotoViewCell: UIView {
    public typealias DisplayView = UIView & SlidingPhotoDisplayable
    public static var displayViewClass: DisplayView.Type = UIImageView.self
    
    open internal(set) var index: Int = -1
    internal var reusable: Bool = true
    
    let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.clipsToBounds = true
        view.scrollsToTop = true
        view.bounces = true
        view.bouncesZoom = true
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        view.showsVerticalScrollIndicator = true
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.maximumZoomScale = 3
        view.minimumZoomScale = 1
        return view
    }()
    
    public let displayView: DisplayView = {
        let view = SlidingPhotoViewCell.displayViewClass.init()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutContents()
    }
    
    private func setup() {
        clipsToBounds = true
        
        scrollView.frame = bounds
        scrollView.delegate = self
        addSubview(scrollView)
        
        displayView.frame = bounds
        scrollView.addSubview(displayView)
    }
    
    private func layoutContents() {
        scrollView.zoomScale = 1
        scrollView.frame = bounds
        
        let height: CGFloat
        if let image = displayView.image {
            height = image.size.height * bounds.width / image.size.width
        } else {
            height = bounds.height
        }
        let size = CGSize(width: bounds.width, height: height)
        displayView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        
        centerContents()
    }
    
    private func centerContents() {
        var top: CGFloat = 0, left: CGFloat = 0
        if scrollView.contentSize.height < scrollView.bounds.height {
            top = (scrollView.bounds.height - scrollView.contentSize.height) * 0.5
        }
        if scrollView.contentSize.width < scrollView.bounds.width {
            left = (scrollView.bounds.width - scrollView.contentSize.width) * 0.5
        }
        scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
    }
    
    func onDoubleTap(sender: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        } else {
            let scale = scrollView.maximumZoomScale
            let width = bounds.width / scale
            let height = bounds.height / scale
            let touchPoint = sender.location(in: displayView)
            let rect = CGRect(x: touchPoint.x - width * 0.5, y: touchPoint.y - height * 0.5, width: width, height: height)
            scrollView.zoom(to: rect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SlidingPhotoViewCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return displayView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContents()
    }
}

// MARK: -

public extension SlidingPhotoViewCell {
    public var image: UIImage? {
        get {
            return displayView.image
        }
        set {
            let current = CACurrentMediaTime()
            
            displayView.image = newValue
            
            if let image = newValue {
                let iw = image.size.width
                let ih = image.size.height
                let vw = bounds.width
                let vh = bounds.height
                let scale = (ih / iw) / (vh / vw)
                if !scale.isNaN && scale > 1.0 {
                    // image: h > w
                    contentMode = .scaleAspectFill
                    layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: (iw / ih) * (vh / vw))
                } else {
                    // image: w > h
                    contentMode = .scaleAspectFit
                    layer.contentsRect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
                }
            }
            
            if CACurrentMediaTime() - current > 0.2 {
                layer.add(CATransition(), forKey: kCATransition)
            }
            
            layoutContents()
        }
    }
}
