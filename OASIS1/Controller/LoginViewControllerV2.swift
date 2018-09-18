//
//  LoginViewController.swift
//  OASIS1
//
//  Created by Honey on 7/27/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import ILLoginKit
import Firebase

class LoginViewControllerV2: UIViewController {
    
    
    deinit {
        //FIX: it does not de-init
        print("loginviewcontrollerv2 v2 is de-init")
    }
    
    var hasShownLogin = false
    var loginCoordinator: LoginCoordinatorV2?
    var loginCoordinatorVC : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard !hasShownLogin else {
            return
        }
        
        loginCoordinatorVC = UIViewController()
        self.present(loginCoordinatorVC!, animated: true) {
            self.loginCoordinator = LoginCoordinatorV2(rootViewController: self.loginCoordinatorVC!)
            self.loginCoordinator!.start()
        }

        hasShownLogin = true
        
        print("login started init.")
    }

    
}

class LoginCoordinatorV2: ILLoginKit.LoginCoordinator {
    
    // MARK: - LoginCoordinator
    
    deinit {
        print("logincoordinator v2 is de-init")
    }
    
    override func start(animated: Bool = true) {
        configureAppearance()
        super.start(animated: animated)
        
    }
    
    override func finish(animated: Bool = true) {
        super.finish(animated: animated)
    }
    
    // MARK: - Setup
    
    // Customize LoginKit. All properties have defaults, only set the ones you want.
    func configureAppearance() {
        // Customize the look with background & logo images
        //configuration.backgroundImage = UIImage(named: "Astroworld1")!
        //mainLogoimage =
        // secondaryLogoImage =
        
        // Change colors
        //configuration.tintColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1)
        //configuration.errorTintColor = UIColor(red: 253.0/255.0, green: 227.0/255.0, blue: 167.0/255.0, alpha: 1)
        
        configuration.tintColor = UIColor(red:0.985, green:0.14, blue:0.35, alpha:1.0)
        configuration.errorTintColor = UIColor.white
        
        // Change placeholder & button texts, useful for different marketing style or language.
        configuration.loginButtonText = "Sign In"
        configuration.signupButtonText = "Create Account"
        configuration.facebookButtonText = "Login with Facebook"
        configuration.forgotPasswordButtonText = "Forgot password?"
        configuration.recoverPasswordButtonText = "Recover"
        configuration.namePlaceholder = "Username"
        configuration.emailPlaceholder = "E-Mail"
        configuration.passwordPlaceholder = "Password"
        configuration.repeatPasswordPlaceholder = "Confirm password!"
        
        configuration.shouldShowFacebookButton = false
        
    }
    
    // MARK: - Completion Callbacks
    
    // Handle login via your API
    override func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let _ = error {
                //if login failure
                //FIX: response words what to say login + sign up
                let alert = UIAlertController(title: "Login credentials incorrect.", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.rootViewController!.presentedViewController?.present(alert, animated: true, completion: nil)
                
                return
            }
            
            self.finish(animated: false)
            //self.goToMapVC()
            
        }
    }
    
    // Handle signup via your API
    override func signup(name: String, email: String, password: String) {
        //print("Signup with: name = \(name) email =\(email) password = \(password)")
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            guard let _ = authResult?.user.email, error == nil else {
                // if sign up failure
                let alert = UIAlertController(title: "Something isn't let this go through. Please try again.", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.rootViewController!.presentedViewController?.present(alert, animated: true, completion: nil)
            
                return
            }
            
            
            self.finish(animated: false)
            //self.goToMapVC()
            //trigger from appdelegate userAuth change function
            
            
        }
    }
    
    func goToMapVC() {
        //FIX: loginViewControllerv2 + coordinator is not dismissed.

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        

        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapVC = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        appDelegate.window?.rootViewController = mapVC
        
    }
    
    
    // Handle password recovery via your API
    override func recoverPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if error == nil {
                let alert = UIAlertController(title: "Something isn't let this go through. Please try again.", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.rootViewController!.presentedViewController?.present(alert, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Email sent.", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.rootViewController!.presentedViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
