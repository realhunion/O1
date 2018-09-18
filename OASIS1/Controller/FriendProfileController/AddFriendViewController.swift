//
//  AddFriendViewController.swift
//  OASIS1
//
//  Created by Honey on 8/19/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Firebase

class AddFriendViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var searchField: UITextField!
    
    
    // Variables
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    var loadingIndicator : UIActivityIndicatorView!

    

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
        
        startDismissGesture()
        // Do any additional setup after loading the view.
        searchField.delegate = self
        self.searchField.becomeFirstResponder()
    }
    
    deinit {
        print("addFriendVC is de-init")
    }
    
    
    
    // Set Up View
    
    func setUpView() {
        
        searchField.layer.cornerRadius = 10.0
        searchField.layer.borderWidth = 1
        searchField.layer.borderColor = UIColor.clear.cgColor
        
        
        setupLoadingIndicatory()
    }
    
    
    // Loading Indicator
    
    func setupLoadingIndicatory() {
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        
        loadingIndicator.center = CGPoint(x: self.view.frame.width * (1/2), y: self.view.frame.height * (4/5))
        
        self.view.addSubview(loadingIndicator)
    }
    
    
    
    
    
    // UITextFielDelegate Stubs
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let txt = textField.text {
            searchPressed(userHandle: txt)
        }
        return true
    }
    
    
    
    
    // Manage Dismiss gesture
    
    func startDismissGesture() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleDismissTap(sender:)))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleDismissTap(sender: UIGestureRecognizer) {
        searchField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
    
    
    
    
    
    
    //Redirect when search button pressed
    
    func searchPressed(userHandle : String) {
        
        searchField.resignFirstResponder()
        searchField.isEnabled = false
        loadingIndicator.startAnimating()
        
        db.collection("User-Handles").document(userHandle).getDocument { (snap, error) in
            guard let doc = snap else { return }

            if let foundUID = doc.data()?["userID"] as? String {
                self.animateUserFound(uid: foundUID)
            } else {
                self.animateUserNotFound()
            }
            
        }
        
        
        
    }
    
    func animateUserNotFound() {
        self.searchField.backgroundColor = UIColor.flatRed()
        UIView.animate(withDuration: 0.75) {
            self.searchField.backgroundColor = UIColor.clear
        }
        
        loadingIndicator.stopAnimating()
        searchField.isEnabled = true
        self.searchField.becomeFirstResponder()
        
    }
    
    func animateUserFound(uid : String) {
        self.searchField.backgroundColor = UIColor.flatGreen()
        UIView.animate(withDuration: 0.75) {
            self.searchField.backgroundColor = UIColor.clear
        }
        if let parentVC = self.presentingViewController as? UITabBarController {
            if let manageVC = parentVC.selectedViewController as? ManageFriendsViewController {
                self.dismiss(animated: true) {
                    manageVC.presentProfileVC(theUserID: uid)
                }
            }
        }
    }
    
    

}








extension AddFriendViewController: MIBlurPopupDelegate {
    
    var popupView: UIView {
        return UIView()
    }
    
    var blurEffectStyle: UIBlurEffectStyle {
        return .dark
    }
    
    var initialScaleAmmount: CGFloat {
        return 0.0
    }
    
    var animationDuration: TimeInterval {
        return 0.4
    }
    
}
