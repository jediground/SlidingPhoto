//
//  SlidingPhotoView.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class SlidingPhotoView: UIView {
    @IBInspectable open var pageSpacing: CGFloat = 20 {
        didSet {
            scrollViewWidthAnchor.constant = pageSpacing
            setNeedsUpdateConstraints()
        }
    }
    
    open private(set) var currentPage: Int = 0 {
        didSet {
            if oldValue != currentPage {
                delegate?.slidingPhotoView?(self, didUpdatePageTo: currentPage)
            }
        }
    }
    
    open func scrollToItem(at index: Int, animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0), animated: animated)
        currentPage = index
    }
    
    @IBOutlet open weak var dataSource: SlidingPhotoViewDataSource? {
        didSet {
            reloadData()
        }
    }
    
    @IBOutlet open weak var delegate: SlidingPhotoViewDelegate?
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.clipsToBounds = true
        view.scrollsToTop = false
        view.bounces = true
        view.bouncesZoom = true
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = true
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.delaysContentTouches = false
        view.canCancelContentTouches = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var scrollViewWidthAnchor: NSLayoutConstraint!
    
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
        reloadData()
    }
    
    private final class DismissPanGestureRecognizer: UIPanGestureRecognizer {
        override var delegate: UIGestureRecognizerDelegate? {
            didSet {
                if let delegate = delegate {
                    assert(delegate.isKind(of: SlidingPhotoView.self), "'SlidingPhotoView built-in pan gesture recognizer must have itself as its delegate.'")
                }
            }
        }
    }
    private(set) var panGestureRecognizer: UIPanGestureRecognizer = DismissPanGestureRecognizer()
    
    private func setup() {
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scrollView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        scrollViewWidthAnchor = scrollView.widthAnchor.constraint(equalTo: widthAnchor, constant: pageSpacing)
        scrollViewWidthAnchor.isActive = true
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(sender:)))
        addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(doubleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(sender:)))
        addGestureRecognizer(longPress)
        
        panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    private func reloadData() {
        guard let dataSource = dataSource else { return }
        
        let itemWidth = scrollView.bounds.width
        let itemHeight = scrollView.bounds.height
        guard itemWidth > 0 && itemHeight > 0 else { return }
        let numberOfItems = dataSource.numberOfItems(in: self)
        
        scrollView.alwaysBounceHorizontal = numberOfItems > 0
        scrollView.contentSize = CGSize(width: CGFloat(numberOfItems) * itemWidth, height: itemHeight)
        scrollView.scrollRectToVisible(CGRect(x: itemWidth * CGFloat(currentPage), y: 0, width: itemWidth, height: itemHeight), animated: false)
        scrollViewDidScroll(scrollView)
    }

    private var reusableCells: [SlidingPhotoViewCell] = []
}

extension SlidingPhotoView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Mark cell as reusable if needed
        markCellAsReusableIfNeeded()
        
        guard let dataSource = dataSource else { return }
        
        // Load preview & next page
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        let range = page - 1 ... page + 1
        let numberOfItems = dataSource.numberOfItems(in: self)
        assert(numberOfItems >= 0, "Fatal Error: `numberOfItems` should >= 0.")
        
        for index in range where index >= 0 && index < numberOfItems {
            let cell = acquireCell(for: index)
            if cell.reusable {
                cell.reusable = false
                dataSource.slidingPhotoView(self, loadContentsFor: cell)
            }
        }
        
        currentPage = page
    }
    
    private func markCellAsReusableIfNeeded() {
        reusableCells.lazy.filter({ !$0.reusable }).forEach { cell in
            let offset = scrollView.contentOffset.x
            let width = scrollView.bounds.width
            if cell.frame.minX > offset + 2.0 * width || cell.frame.maxX < offset - width {
                cell.reusable = true
                cell.index = -1
            }
        }
    }
    
    private func acquireCell(`for` index: Int) -> SlidingPhotoViewCell {
        return loadedCell(of: index) ?? dequeueReusableCell(for: index)
    }
    
    private func loadedCell(of index: Int) -> SlidingPhotoViewCell? {
        return reusableCells.lazy.filter({ $0.index == index }).first
    }
    
    private func dequeueReusableCell(`for` index: Int) -> SlidingPhotoViewCell {
        let one: SlidingPhotoViewCell = reusableCells.lazy.filter({ $0.reusable }).first ?? SlidingPhotoViewCell()
        var rect = bounds
        rect.origin.x = rect.size.width * CGFloat(index) + pageSpacing * (CGFloat(index) + 0.5)
        one.frame = rect
        one.index = index
        if nil == one.superview {
            one.scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
            scrollView.addSubview(one)
            reusableCells.append(one)
        }
        return one
    }
}

// MARK: - Gestures

private extension SlidingPhotoView {
    @objc private func onSingleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended, let cell = loadedCell(of: currentPage), let delegate = delegate else { return }
        let touchPoint = sender.location(in: cell)
        delegate.slidingPhotoView?(self, didSingleTappedAt: touchPoint, in: cell)
    }
    
    @objc private func onDoubleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended, let cell = loadedCell(of: currentPage) else { return }
        cell.onDoubleTap(sender: sender)
    }
    
    @objc private func onLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended, let cell = loadedCell(of: currentPage), let delegate = delegate else { return }
        let touchPoint = sender.location(in: cell)
        delegate.slidingPhotoView?(self, didLongPressedAt: touchPoint, in: cell)
    }
}

extension SlidingPhotoView: UIGestureRecognizerDelegate {
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view)
            if abs(velocity.y) > abs(velocity.x), let cell = loadedCell(of: currentPage), cell.scrollView.zoomScale == 1.0, !cell.scrollView.isDragging, !cell.scrollView.isDecelerating {
                let contentHeight = cell.scrollView.contentSize.height
                let boundsHeight = cell.scrollView.bounds.size.height
                let offsetY = cell.scrollView.contentOffset.y
                if contentHeight > boundsHeight {
                    if offsetY <= 0 {
                        return velocity.y > 250
                    }
                    if offsetY + boundsHeight >= contentHeight {
                        return velocity.y < -250
                    }
                } else {
                    return true
                }
            }
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
