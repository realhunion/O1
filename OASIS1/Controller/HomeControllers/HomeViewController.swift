//
//  HomeViewController.swift
//  OASIS1
//
//  Created by Honey on 7/28/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
        // Do any additional setup after loading the view.
    }
    
    
    deinit {
        print("Home REAL VC is de-init")
    }
    

    
    
    
    
    // Mark:- Set Up Home View
    
    func setUpView() {
        
        let maskLayer = CAShapeLayer()
        let maskPath: UIBezierPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: ([.topLeft, .topRight]), cornerRadii: CGSize(width: 10.0, height: 10.0))
        maskLayer.frame = view.bounds
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        
        view.addInnerShadow(onSide: .top, shadowColor: UIColor.black, shadowSize: 3.5, shadowOpacity: 0.5)
        
    }
}
