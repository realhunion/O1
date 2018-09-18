//
//  ChangeProfileNameViewController.swift
//  OASIS1
//
//  Created by Honey on 8/23/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Firebase

class ChangeProfileNameViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    
    var isForGhost : Bool!
    
    
    @IBOutlet weak var textField: UITextField!
    
    

    // Variables
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    var loadingIndicator : UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
        
        startDismissGesture()

        textField.delegate = self
        self.textField.becomeFirstResponder()
    }
    
    deinit {
        print("change name is de-init")
    }
    
    
    
    // Set Up View
    
    func setUpView() {
        
        textField.layer.cornerRadius = 10.0
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.clear.cgColor
        
        
        setupLoadingIndicatory()
    }
    
    
    // Loading Indicator
    
    func setupLoadingIndicatory() {
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        
        loadingIndicator.center = CGPoint(x: self.view.frame.width * (1/2), y: self.view.frame.height * (4/5))
        
        self.view.addSubview(loadingIndicator)
    }
    
    
    
    // Manage Dismiss gesture
    
    func startDismissGesture() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleDismissTap(sender:)))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleDismissTap(sender: UIGestureRecognizer) {
        textField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
    
    
    
    // UITextFielDelegate Stubs
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let txt = textField.text {
            goPressed(nameChangeText: txt)
        }
        return true
    }
    
    

    
    
    
    
    func matchesRegex(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    func isNameSyntaxCorrect(nameString : String) -> Bool {
        let validSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ ")
        
        if nameString.rangeOfCharacter(from: validSet.inverted) != nil {
            return false
        }
        else if matchesRegex(for: "[a-zA-Z]{2,50}", in: nameString).count == 0 {
            return false
        }
        else {
            return true
        }
    }
    
    //Redirect when search button pressed
    
    func goPressed(nameChangeText : String) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        textField.resignFirstResponder()
        textField.isEnabled = false
        loadingIndicator.startAnimating()
        
        if isNameSyntaxCorrect(nameString: nameChangeText) {
            
            var payload = [:] as [String:Any]
            if isForGhost {
                payload = ["ghostName" : nameChangeText]
            } else {
                payload = ["userName" : nameChangeText]
            }
        
            
            db.collection("User-Profile").document(uid).setData(payload, merge: true) { (error) in
                if error != nil {
                    self.animateNotValid()
                } else {
                    self.animateValid()
                }
            }
        } else {
            animateNotValid()
        }
        
        
    }
    
    func animateNotValid() {
        self.textField.backgroundColor = UIColor.flatRed()
        UIView.animate(withDuration: 0.75) {
            self.textField.backgroundColor = UIColor.clear
        }
        
        loadingIndicator.stopAnimating()
        textField.isEnabled = true
        self.textField.becomeFirstResponder()
        
    }
    
    func animateValid() {
//        self.textField.backgroundColor = UIColor.flatGreen()
//        UIView.animate(withDuration: 0.75) {
//            self.textField.backgroundColor = UIColor.clear
//        }
        if let parentVC = self.presentingViewController as? UITabBarController {
            if let manageVC = parentVC.selectedViewController as? ManageProfileViewController {
                self.dismiss(animated: true)
            }
        }
    }
    
    
    
}





extension ChangeProfileNameViewController: MIBlurPopupDelegate {
    
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
