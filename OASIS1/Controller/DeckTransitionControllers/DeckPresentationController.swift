//
//  DeckPresentationController.swift
//  OASIS1
//
//  Created by Honey on 7/15/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit

class DeckPresentationViewController: UIViewController, UIViewControllerTransitioningDelegate, DeckTransitionDelegate {


    // Animators
    var presentationAnimator: PresentationController?


    
    
    // DeckTransitionDelegate
    
    func update(withProgress progress: CGFloat) {
        print("progress CCCC: \(progress)")
        view.transform =
            CGAffineTransform.identity.scaledBy(x: Constant.homeScaleX + (1-Constant.homeScaleX) * progress,
                                                y: Constant.homeScaleY + (1-Constant.homeScaleY) * progress)

    }
    
    
    
    
    
    //MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        presentationAnimator?.state = .presenting
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator?.state = .hidden
        return presentationAnimator
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        self.presentationAnimator = PresentationController(presentedViewController: presented, presenting: presenting)
        return presentationAnimator
    }

    
    /////
    /////
    /////

}
