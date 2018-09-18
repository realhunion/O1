//
//  VCSwitcherModel.swift
//  OASIS1
//
//  Created by Honey on 8/1/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class VCSwitcherModel {
    
    
    // Create a singleton instance
    static let sharedInstance: VCSwitcherModel = { return VCSwitcherModel() }()
    
    
    
    enum typeVC {
        case mapVC
        case loginVC
        case connectionLostVC
    }
    
    var coreFireFriendsList : CoreFireFriendsList
    var coreFireFriendRequests : CoreFireFriendRequests
    var coreFireMyProfile : CoreFireMyProfile
    var network : NetworkManager
    var appDelegate : AppDelegate
    
    
    
    init() {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        coreFireFriendsList = CoreFireFriendsList.sharedInstance
        coreFireFriendRequests = CoreFireFriendRequests.sharedInstance
        coreFireMyProfile = CoreFireMyProfile.sharedInstance
        
        network = NetworkManager.sharedInstance
        startAuthListener()
        startNetworkListener()
        
        print("VCSWITCHER is init")
    }
    
    
    

    func initRespectiveVC(theVC : typeVC) {
        
        switch theVC {
            
        case .mapVC:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
            appDelegate.window?.rootViewController = vc
            
        case .loginVC:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewControllerV2") as! LoginViewControllerV2
            appDelegate.window?.rootViewController = vc
            
        case .connectionLostVC:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ConnectionLostVC") as! ConnectionLostVC
            appDelegate.window?.rootViewController = vc
        }
    }
    
    
    func deInitRespectiveVC() {
        
        guard let rootVC = appDelegate.window?.rootViewController else {
            return
        }
        
        
        if let mapVC = rootVC as? MapViewController {
            
            if let p = mapVC.presentedViewController as? HomeShellViewController {
                p.dismiss(animated: true, completion: nil)
            }

            if let p = mapVC.presentedViewController as? CircleChatViewController {
                p.dismiss(animated: true, completion: nil)
            }
            
            mapVC.deInitNecessities()
        }
        
        if let loginVC = rootVC as? LoginViewControllerV2 {
            loginVC.loginCoordinator?.finish()
            loginVC.dismiss(animated: true, completion: nil)
        }
        
        if let _ = rootVC as? ConnectionLostVC {
            
        }
    }
    
    
    
    
    func startAuthListener() {
        
        let _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let uid = user?.uid {
                self.deInitRespectiveVC()
                self.startFriendsListCoreDataModel(UID: uid)
                self.startFriendRequestsCoreDataModel(UID: uid)
                self.startMyProfileCoreDataModel(UID: uid)
                self.initRespectiveVC(theVC: .mapVC)
                print("(init...) auth is logged in")
            }
            else {
                self.deInitRespectiveVC()
                self.stopFriendsListCoreDataModel()
                self.stopFriendRequestsCoreDataModel()
                self.stopMyProfileCoreDataModel()
                self.initRespectiveVC(theVC: .loginVC)
                print("(init...) auth is logged out.")
            }
        }
    }
    
    
    var isNetworkDown = false
    func startNetworkListener() {
        
        network.reachability.whenUnreachable = { reachability in
            
            self.deInitRespectiveVC()
            self.initRespectiveVC(theVC: .connectionLostVC)
            self.isNetworkDown = true

        }
        
        network.reachability.whenReachable = { reachability in
            
            if self.isNetworkDown == false {
                return
            }
            
            self.deInitRespectiveVC()
            
            if Auth.auth().currentUser == nil {
                self.initRespectiveVC(theVC: .loginVC)
            } else {
                self.initRespectiveVC(theVC: .mapVC)
            }
            
            self.isNetworkDown = false
            
        }
    }
    
    
    
    
    func startFriendsListCoreDataModel(UID : String) {
        //stopFriendsListCoreDataModel()
        coreFireFriendsList.startUserbaseFirebaseConnection(myUID: UID)
    }
    
    func stopFriendsListCoreDataModel() {
        coreFireFriendsList.shutDown()
        coreFireFriendsList.deleteAllData()
    }
    
    
    
    func startFriendRequestsCoreDataModel(UID : String) {
        //stopFriendRequestsCoreDataModel()
        coreFireFriendRequests.startUserbaseFirebaseConnection(myUID: UID)
    }
    
    func stopFriendRequestsCoreDataModel() {
        coreFireFriendRequests.shutDown()
        coreFireFriendRequests.deleteAllData()
    }
    
    
    func startMyProfileCoreDataModel(UID : String) {
        stopMyProfileCoreDataModel()
        coreFireMyProfile.startUserbaseFirebaseConnection(myUID: UID)
    }
    
    func stopMyProfileCoreDataModel() {
        coreFireMyProfile.shutDown()
        coreFireMyProfile.deleteAllData()
    }
    
}
