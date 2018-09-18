//
//  HomeShellVC.swift
//  OASIS1
//
//  Created by Honey on 7/28/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit

class HomeShellViewController: DeckPresentedViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    deinit {
        print("Home shell VC is de-init")
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        
        super.dismiss(animated: flag, completion: completion)
        
        if let presentatingVC = presentingViewController as? MapViewController {
            presentatingVC.presentationAnimator = nil
        }
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
