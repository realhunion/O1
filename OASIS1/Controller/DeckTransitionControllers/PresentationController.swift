//
//  PresentationController.swift
//  OASIS1
//
//  Created by Honey on 7/15/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import UIKit

private extension TimeInterval {
    static let duration: TimeInterval = 0.6
}

private extension CGFloat {
    static let blackLayerAlpha: CGFloat = 0.75
    static let cornerRadius: CGFloat = 10
    static let presantingSpringWithDamping: CGFloat = 0.9
    static let presantingInitialSpringVelocity: CGFloat = 0.8
    static let hiddenSpringWithDamping: CGFloat = 0.8
    static let hiddenInitialSpringVelocity: CGFloat = 0.8
    static let contentsViewYOffset: CGFloat = 20
    //20
    static let contentsViewYCoeff: CGFloat = 0.05
    //0.05
}

class PresentationController: UIPresentationController, UIViewControllerAnimatedTransitioning {
    
    // Models
    enum State {
        case presenting // the cover is shown
        case hidden // the cover is hidden
    }
    
    var state: State = .hidden
    
    private var blackLayer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        return view
    }()
    
    // MARK: - Transition Lifecycle
    
    override func presentationTransitionWillBegin() {
        guard let fromView = presentingViewController.view,
            let coordinator = presentedViewController.transitionCoordinator,
            let presentingVC = presentingViewController as? UIViewController,
            let contentsView = presentingVC.view else { return }
        
        
        blackLayer.frame = fromView.frame
        contentsView.addSubview(blackLayer)
        coordinator.animate(alongsideTransition: { (context) in
            self.blackLayer.alpha = .blackLayerAlpha
        })
    }
    
    // For dismiss
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else { return }
        coordinator.animate(alongsideTransition: { (context) in
            self.blackLayer.alpha = 0
        }) { (context) in
            if !context.isCancelled {
                self.blackLayer.removeFromSuperview()
            }
        }
    }
    
    //MARK: - Private
    
    private func showPresentingAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presented = presentedView,
            let container = containerView,
            let presentedVC = presentedViewController as? UIViewController,
            let presentingVC = presentingViewController as? UIViewController,
            let contentsView = presentingVC.view else { return }
        
        container.addSubview(presented)
        presented.frame = CGRect(x: 0,
                                 y: container.bounds.height,
                                 width: container.bounds.width,
                                 height: Constant.pinnedBarHeight)
        UIView.animate(withDuration: .duration, delay: 0, usingSpringWithDamping: .presantingSpringWithDamping, initialSpringVelocity: .presantingInitialSpringVelocity, options: .curveEaseInOut, animations: {
            contentsView.layer.cornerRadius = .cornerRadius
            contentsView.layer.maskedCorners =
                [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            contentsView.clipsToBounds = true
            
            contentsView.transform = contentsView.transform.scaledBy(x: Constant.homeScaleX, y: Constant.homeScaleY)
            //contentsView.transform = CGAffineTransform.identity.scaledBy(x: Constant.homeScaleX, y: Constant.homeScaleY)
            
            contentsView.transform = contentsView.transform.translatedBy(x: 0, y: .contentsViewYOffset - container.bounds.height * .contentsViewYCoeff / 2)
            presented.frame = CGRect(x: 0,
                                     y: 0,
                                     width: container.bounds.width,
                                     height: container.bounds.height)
            presented.layer.cornerRadius = .cornerRadius
            presented.layer.maskedCorners =
                [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            presented.clipsToBounds = true
        }, completion: { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    public func showHiddenAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presented = presentedView,
            let container = containerView,
            let presentedVC = presentedViewController as? UIViewController,
            let presentingVC = presentingViewController as? UIViewController,
            let contentsView = presentingVC.view else { return }
        
        UIView.animate(withDuration: .duration,
                       delay: 0,
                       usingSpringWithDamping: .hiddenSpringWithDamping,
                       initialSpringVelocity: .hiddenInitialSpringVelocity,
                       options: .curveEaseInOut,
                       animations: {
                        
                        contentsView.layer.cornerRadius = 0
                        contentsView.transform = CGAffineTransform.identity
                        contentsView.frame = container.frame
                        presented.layer.cornerRadius = 0
                        presented.frame = CGRect(x: 0,
                                                 y: container.bounds.height,
                                                 width: container.bounds.width,
                                                 height: 0)
        }, completion: { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    //MARK: - UIViewControllerAnimatedTransitioning
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return .duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch state {
        case .presenting:
            showPresentingAnimation(using: transitionContext)
        default:
            showHiddenAnimation(using: transitionContext)
        }
    }
}

