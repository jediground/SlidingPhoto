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
                delegate?.slidingPhotoView?(self, didUpdateFocus: acquireCell(for: currentPage))
            }
        }
    }
    
    open func scrollToItem(at index: Int, animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0), animated: animated)
        currentPage = index
    }
    
    @IBOutlet open weak var dataSource: SlidingPhotoViewDataSource? {
        didSet {
            if oldValue?.isEqual(dataSource) == false {
                reloadData()
            }
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
    
    private var cellClass: SlidingPhotoViewCell.Type?
    open func register<T: SlidingPhotoViewCell>(_ cellClass: T.Type) {
        if nil != cellNib { return }
        self.cellClass = cellClass
    }

    private var cellNib: UINib?
    open func register(_ cellNib: UINib) {
        if nil != cellClass { return }
        self.cellNib = cellNib
    }
}

extension SlidingPhotoView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let dataSource = dataSource else { return }
        
        let numberOfItems = dataSource.numberOfItems(in: self)
        assert(numberOfItems >= 0, "Fatal Error: `numberOfItems` should >= 0.")
        
        // Load preview & next page
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width + 0.5)
        let range = max(page - 1, 0) ... min(page + 1, numberOfItems - 1)
        
        // Mark cell as reusable if needed
        purgeCellsExclude(range)
        
        for index in range {
            let cell = acquireCell(for: index)
            if !cell.prepared {
                cell.prepared = true
                dataSource.slidingPhotoView(self, prepareForDisplay: cell)
            }
        }
        
        if (0 ..< numberOfItems).contains(page) {
            currentPage = page
        }
    }
    
    private func purgeCellsExclude(_ range: ClosedRange<Int>) {
        reusableCells.lazy.filter({ !range.contains($0.index) }).forEach { cell in
            let offset = scrollView.contentOffset.x
            let width = scrollView.bounds.width
            if cell.prepared && (cell.frame.minX > offset + 2.0 * width || cell.frame.maxX < offset - width) {
                delegate?.slidingPhotoView?(self, didEndDisplaying: cell)
                cell.prepared = false
                cell.index = -1
            }
        }
    }

    func acquireCell(`for` index: Int) -> SlidingPhotoViewCell {
        return loadedCell(of: index) ?? dequeueReusableCell(for: index)
    }
    
    private func loadedCell(of index: Int) -> SlidingPhotoViewCell? {
        return reusableCells.lazy.filter({ $0.index == index }).first
    }
    
    private func dequeueReusableCell(`for` index: Int) -> SlidingPhotoViewCell {
        let one: SlidingPhotoViewCell
        if let first = reusableCells.lazy.filter({ !$0.prepared }).first {
            one = first
        } else if let cellClass = cellClass {
            one = cellClass.init()
        } else if let cellNib = cellNib, let cell = cellNib.instantiate(withOwner: nil, options: nil).first {
            assert(cell is SlidingPhotoViewCell, "Registered cell nib must be kind of `SlidingPhotoViewCell`.")
            one = cell as! SlidingPhotoViewCell
        } else {
            one = SlidingPhotoViewCell()
        }
        
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
        if cell.scrollView.zoomScale != 1 {
            cell.scrollView.setZoomScale(1, animated: true)
        }
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
