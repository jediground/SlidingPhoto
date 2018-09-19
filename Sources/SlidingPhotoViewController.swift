//
//  SlidingPhotoViewController.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class SlidingPhotoViewController: UIViewController {
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        transitioningDelegate = self
    }
    
    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open var backgroundViewColor: UIColor? {
        get {
            return backgroundView.backgroundColor
        }
        set {
            backgroundView.backgroundColor = newValue
        }
    }

    public let slidingPhotoView: SlidingPhotoView = SlidingPhotoView()    

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(backgroundView)
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        slidingPhotoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slidingPhotoView)
        slidingPhotoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        slidingPhotoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        slidingPhotoView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        slidingPhotoView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        slidingPhotoView.delegate = self
        slidingPhotoView.dataSource = self
        slidingPhotoView.panGestureRecognizer.addTarget(self, action: #selector(onPan(sender:)))
    }
}

extension SlidingPhotoViewController: SlidingPhotoViewDataSource, SlidingPhotoViewDelegate {
    open func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int { return 0 }
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, loadContentsFor cell: SlidingPhotoViewCell) {}
    
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdatePageTo index: Int) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTappedAt location: CGPoint, in cell: SlidingPhotoViewCell) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didLongPressedAt location: CGPoint, in cell: SlidingPhotoViewCell) {}
}

extension SlidingPhotoViewController {
    @objc private func onPan(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            let translation = sender.translation(in: sender.view).y
            let ratio = abs(translation / view.bounds.size.height)
            slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translation)
            backgroundView.alpha = 1 - ratio
        case .ended:
            let velocity = sender.velocity(in: sender.view).y
            let translation = sender.translation(in: sender.view).y
            let isMoveUp = velocity < -1000 && translation < 0
            let isMoveDown = velocity > 1000 && translation > 0
            
            if isMoveUp || isMoveDown {
                let height = slidingPhotoView.bounds.size.height
                let duration = TimeInterval(0.25 * (height - abs(translation)) / height)
                let translationY = height * (isMoveUp ? -1.0 : 1.0)
                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    self.slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translationY)
                    self.backgroundView.alpha = 0
                }, completion: { _ in
                    self.presentingViewController?.dismiss(animated: false, completion: nil)
                })
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
                    self.slidingPhotoView.transform = .identity
                    self.backgroundView.alpha = 1
                }, completion: nil)
            }
        default:
            slidingPhotoView.transform = .identity
            backgroundView.alpha = 1
        }
    }
}

extension SlidingPhotoViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentationAnimator(vc: self)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissionAnimator(vc: self)
    }
}

private final class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var vc: SlidingPhotoViewController!
    init(vc: SlidingPhotoViewController) {
        self.vc = vc
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to) else {
            return transitionContext.completeTransition(false)
        }
        let container = transitionContext.containerView
        to.view.frame = container.bounds
        container.addSubview(to.view)
        
        vc.backgroundView.alpha = 0
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.vc.backgroundView.alpha = 1
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

private final class DismissionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var vc: SlidingPhotoViewController!
    init(vc: SlidingPhotoViewController) {
        self.vc = vc
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let from = transitionContext.viewController(forKey: .from) else {
            return transitionContext.completeTransition(false)
        }
        let container = transitionContext.containerView
        container.addSubview(from.view)
        
        let translationY = vc.slidingPhotoView.bounds.height
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.vc.slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translationY)
            self.vc.backgroundView.alpha = 0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
