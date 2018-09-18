//
//  DeckPresentedViewController.swift
//  OASIS1
//
//  Created by Honey on 7/15/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit

protocol DeckTransitionDelegate: class {
    func update(withProgress progress: CGFloat)
}


class DeckPresentedViewController: UIViewController, UIGestureRecognizerDelegate {
    
    
    // Delegates
    weak var delegate: DeckTransitionDelegate?
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Helpers
    private var originFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    
    //Variables
    let resistanceLevel = 2.0
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGestures()
        
    }
//    override func viewWillAppear(_ animated: Bool) {
//        self.update(withProgress: 0.001)
//        super.viewWillAppear(animated)
//    }
    
    
    
    
    //Need for simultaneous gesture recognition
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    
    
    
    
    
    
    @objc private func panGestureAction(gesture: UIPanGestureRecognizer) {
        let viewTransition = gesture.translation(in: view)
        var progress = viewTransition.y / (originFrame.height - Constant.pinnedBarHeight)
        progress = progress / CGFloat(resistanceLevel)
        
        switch gesture.state {
        case .began:
            originFrame = view.frame
        case .changed:
            if progress >= 0 {
                if progress > Constant.closedProgressNotReturn {
                    endPan(withProgress: progress)
                } else {
                    update(withProgress: progress)
                }
            } else {
                break
            }
        case .cancelled:
            break
        case .ended:
            endPan(withProgress: progress)
            break
        default:
            break
        }
    }
    
    
    // MARK: - Handle Transition Progress
    private func update(withProgress progress: CGFloat) {
        delegate?.update(withProgress: progress)
        view.frame = CGRect(x: 0,
                            y: originFrame.origin.y + (originFrame.height) * progress,
                            width: view.bounds.width,
                            height: view.bounds.height)
    }
    
    
    // MARK: - Handle end of the transition
    public func endPan(withProgress progress: CGFloat) {
        if progress > Constant.closedProgressNotReturn {
            //dismiss(animated: true, completion: nil)
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            print("progress BBB : \(progress)")
            UIView.animate(withDuration: 0.2 + 0.2 * Double(progress), delay: 0, options: .curveEaseInOut, animations: {
                self.delegate?.update(withProgress: 0)
                self.view.frame = self.originFrame
            })
        }
    }
    
    
    // MARK: - Setup Gestures
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(panGestureAction(gesture:)))
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        
        view.addGestureRecognizer(pan)
    }
    
    
    

}

//class DeckPresentedViewControllerV2: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDelegate {
//
//
//    // Delegates
//    weak var delegate: DeckTransitionDelegate?
//
//
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
//
//    // Helpers
//    private var originFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
//
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        originFrame = view.frame
//
//        setupGestures()
//
//    }
//
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        return true
//    }
//
//
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//
//        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
//        if translation.y < 0 {
//            return
//        }
//
//        let yOffSet = scrollView.contentOffset.y
//        let progress = (-1.0 * yOffSet) / (originFrame.height - Constant.pinnedBarHeight)
//
//        print("progress: \(progress), yOffSet: \(yOffSet)")
//
//        if yOffSet > 0 {
//            return
//        }
//
//        if scrollView.isDragging == false {
//            endPan(withProgress: progress)
//        } else {
//            if progress > Constant.closedProgressNotReturn {
//                endPan(withProgress: progress)
//            } else {
//                update(withProgress: progress)
//            }
//        }
//    }
//
//
//
//
//
//
//
//
//
//    @objc private func panGestureAction(gesture: UIPanGestureRecognizer) {
//        let viewTransition = gesture.translation(in: view)
//        let progress = viewTransition.y / (originFrame.height - Constant.pinnedBarHeight)
//
//
//        if let tabVC = self.childViewControllers.last as? UITabBarController, let manageFriendsVC = tabVC.selectedViewController as? ManageFriendsViewController {
//            manageFriendsVC.collectionView?.delegate = self
//        }
//
//
////        switch gesture.state {
////        case .began:
////            originFrame = view.frame
////        case .changed:
////            if progress >= 0 {
////                if progress > Constant.closedProgressNotReturn {
////                    endPan(withProgress: progress)
////                } else {
////                    update(withProgress: progress)
////                }
////            } else {
////                break
////            }
////        case .cancelled:
////            break
////        case .ended:
////            endPan(withProgress: progress)
////            break
////        default:
////            break
////        }
//    }
//
//
//    // MARK: - Handle Transition Progress
//    private func update(withProgress progress: CGFloat) {
//        delegate?.update(withProgress: progress)
//        view.frame = CGRect(x: 0,
//                            y: originFrame.origin.y + (originFrame.height - Constant.pinnedBarHeight) * progress,
//                            width: view.bounds.width,
//                            height: view.bounds.height)
//    }
//
//
//    // MARK: - Handle end of the transition
//    public func endPan(withProgress progress: CGFloat) {
//        if progress > Constant.closedProgressNotReturn {
//            //dismiss(animated: true, completion: nil)
//            self.presentingViewController?.dismiss(animated: true, completion: nil)
//        } else {
//            print("progress BBB : \(progress)")
//            UIView.animate(withDuration: 0.2 + 0.2 * Double(progress), delay: 0, options: .curveEaseInOut, animations: {
//                self.delegate?.update(withProgress: 0)
//                self.view.frame = self.originFrame
//            })
//        }
//    }
//
//
//    // MARK: - Setup Gestures
//    private func setupGestures() {
//        let pan = UIPanGestureRecognizer(target: self,
//                                         action: #selector(panGestureAction(gesture:)))
//        pan.delegate = self
//        pan.maximumNumberOfTouches = 1
//        pan.cancelsTouchesInView = false
//
//        view.addGestureRecognizer(pan)
//    }
//
//
//
//
//}
