//
//  FriendProfileViewController.swift
//  OASIS1
//
//  Created by Honey on 8/13/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Firebase
import FirebaseUI
import CoreData

class FriendProfileViewController: UIViewController, UIGestureRecognizerDelegate, FriendManagerProfileUpdated {
    
    
    //Protocol
    func friendProfileUpdated() {
        guard let uid = userID else { return }
        configureProfileButton(theUserID: uid)
    }
    
    
    
    var userID : String?
    
    
    
    @IBOutlet weak var popupContainerView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userHandleLabel: UILabel!
    @IBOutlet weak var profileButton: UIButton!
    

    
    
    //Enum
    enum ProfileStatus {
        case notFriends
        case friends
        case requestSent
        case requestReceived
    }
    
    
    
    //Variables
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    var storageRef : Storage = (UIApplication.shared.delegate as! AppDelegate).storageRef
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let myUserID = Auth.auth().currentUser?.uid
    
    let cfFriendsList = CoreFireFriendsList.sharedInstance
    let cfFriendRequests = CoreFireFriendRequests.sharedInstance
    
    
    
    
    func deinitNeccessities() {
        if let parentVC = self.presentingViewController as? UITabBarController {
            if let manageVC = parentVC.selectedViewController as? ManageFriendsViewController {
                manageVC.delegate = nil
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.deinitNeccessities()
        super.dismiss(animated: flag, completion: completion)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setUpView()

        startDismissGesture()
        
        if let uid = userID {
            startFirebaseDataRetrieval(theUserID: uid)
        }
        
        
    }
    
    deinit {
        print("de-init occured on friend profile vc")
    }
    
    
    
    // Set Up View
    
    func setUpView() {
        popupContainerView.backgroundColor = Constant.myBlackColor
        popupContainerView.layer.cornerRadius = 10
        
        userImageView.layer.cornerRadius = 10
        userImageView.clipsToBounds = true
        userImageView.image = UIImage(named: "Astroworld1")
        
        userImageView.layer.borderColor = Constant.myWhiteColor.cgColor
        userImageView.layer.borderWidth = 2.0
        
        userNameLabel.text = ""
        userHandleLabel.text = ""
        userImageView.image = nil
        
        profileButton.setTitle("", for: .normal)
        profileButton.isHidden = true
        
        profileButton.layer.cornerRadius = 10
        profileButton.layer.borderWidth = 1
        profileButton.layer.borderColor = Constant.myWhiteColor.cgColor
        profileButton.setTitleColor(UIColor.white, for: .normal)
        
    }
    
    
    func updateProfileButton(profileStatus : ProfileStatus) {
        switch profileStatus {
        case .friends:
            UIView.animate(withDuration: 0.7) {
                self.profileButton.layer.borderColor = UIColor(red: 0, green: 118/255, blue: 254/255, alpha: 1).cgColor
                self.profileButton.backgroundColor = UIColor(red: 0, green: 118/255, blue: 254/255, alpha: 1)
                self.profileButton.setTitle("Friends ✓", for: .normal)
            }
        case .requestSent:
            UIView.animate(withDuration: 0.7) {
                self.profileButton.layer.borderColor = UIColor.flatYellowColorDark()?.cgColor
                self.profileButton.backgroundColor = UIColor.flatYellowColorDark()
                self.profileButton.setTitle("Friend Request Sent ➤", for: .normal)
            }
        case .requestReceived:
            UIView.animate(withDuration: 0.7) {
                self.profileButton.layer.borderColor = UIColor.flatGreen()?.cgColor
                self.profileButton.backgroundColor = UIColor.flatGreen()
                self.profileButton.setTitle("Accept Friend Request", for: .normal)
            }
        case .notFriends:
            UIView.animate(withDuration: 0.7) {
                self.profileButton.layer.borderColor = Constant.myWhiteColor.cgColor
                self.profileButton.backgroundColor = UIColor.clear
                self.profileButton.setTitle("Add Friend", for: .normal)
            
            }
        }
    }
    

    
    
    
    
    
    // Manage Dismiss gesture
    
    func startDismissGesture() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleDismissTap(sender:)))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleDismissTap(sender: UIGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
    
    
    
    
    
    
    
    
    // Button Tapped
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        guard let uid = userID, let myUID = Auth.auth().currentUser?.uid else { return }
        
        let profileStatus = returnProfileStatus(theUserID: uid)
        
        print("Current status : \(profileStatus)")
        
        switch profileStatus {
            
        case .friends:
            deleteFriend(deleterUID: myUID, deletedUID: uid) {
                self.updateProfileButton(profileStatus: .notFriends)
            }
            
        case .notFriends:
            sendFriendRequest(fromUID: myUID, toUID: uid) {
                self.updateProfileButton(profileStatus: .requestSent)
            }
        case .requestSent:
            self.updateProfileButton(profileStatus: .requestSent)
        case .requestReceived:
            self.acceptFriendRequest(fromUID: uid, toUID: myUID) {
                self.updateProfileButton(profileStatus: .friends)
            }
        }
    }
    
    
    func sendFriendRequest(fromUID : String, toUID : String, completion: @escaping () -> ()) {
        let outboundData = ["userName":"Bono",
                            "isOutbound":true,
                            "hasSeen":false] as [String : Any]
        db.collection("User-Base").document(fromUID).collection("MyFriendRequests").document(toUID).setData(outboundData)
        
        let inboundData = ["userName":"Bono",
                            "isOutbound":false,
                            "hasSeen":false] as [String : Any]
        db.collection("User-Base").document(toUID).collection("MyFriendRequests").document(fromUID).setData(inboundData)
        
        completion()
    }
    
    func acceptFriendRequest(fromUID : String, toUID : String, completion: @escaping () -> ()) {
        db.collection("User-Base").document(fromUID).collection("MyFriends").document(toUID).setData([:])
        db.collection("User-Base").document(toUID).collection("MyFriends").document(fromUID).setData([:])
        db.collection("User-Base").document(toUID).collection("MyFriendRequests").document(fromUID).delete()
        db.collection("User-Base").document(fromUID).collection("MyFriendRequests").document(toUID).delete()
        completion()
    }
    
    func deleteFriend(deleterUID : String, deletedUID : String, completion: @escaping () -> ()) {
        db.collection("User-Base").document(deletedUID).collection("MyFriends").document(deleterUID).delete()
        db.collection("User-Base").document(deleterUID).collection("MyFriends").document(deletedUID).delete()
        completion()
    }
    
    
    
    
    
    // Firebase Data Retrieval
    
    func startFirebaseDataRetrieval(theUserID : String) {
        db.collection("User-Profile").document(theUserID).getDocument { (snap, error) in
            if let doc = snap {
                
                if let userName = doc.data()?["userName"] as? String, let userHandle = doc.data()?["userHandle"] as? String {
                    self.updateUserNameLabel(userName: userName)
                    self.updateUserHandleLabel(userHandle: userHandle)
                    self.updateUserImageLabel(theUserID: theUserID)
                    
                    self.configureProfileButton(theUserID: theUserID)
                }
            }
        }
    }
    
    
    func configureProfileButton(theUserID : String) {
        if isUserFriend(theUserID: theUserID) {
            updateProfileButton(profileStatus: .friends)
        }
        else if isIncomingFriendRequest(theUserID: theUserID) {
            updateProfileButton(profileStatus: .requestReceived)
        }
        else if isOutgoingFriendRequest(theUserID: theUserID) {
            updateProfileButton(profileStatus: .requestSent)
        }
        else {
            updateProfileButton(profileStatus: .notFriends)
        }
        self.profileButton.isHidden = false
    }
    
    func returnProfileStatus(theUserID : String) -> ProfileStatus {
        if isUserFriend(theUserID: theUserID) {
            return .friends
        }
        else if isIncomingFriendRequest(theUserID: theUserID) {
            return .requestReceived
        }
        else if isOutgoingFriendRequest(theUserID: theUserID) {
            return .requestSent
        }
        else {
            return .notFriends
        }
    }
    
    
    func isUserFriend(theUserID : String) -> Bool {
        let request : NSFetchRequest<MyFriendCoreClass> = MyFriendCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", theUserID)
        do {
            let result = try context.fetch(request)
            
            if let _ = result.first {
                return true
            }
            else {
                return false
            }
        } catch {
            return false
        }
    }
    
    func isIncomingFriendRequest(theUserID : String) -> Bool {
        let request : NSFetchRequest<MyFriendRequestCoreClass> = MyFriendRequestCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", theUserID)
        do {
            let result = try context.fetch(request)
            
            if let x = result.first {
                return !x.isOutbound
            }
            else {
                return false
            }
        } catch {
            return false
        }
    }
    
    func isOutgoingFriendRequest(theUserID : String) -> Bool {
        let request : NSFetchRequest<MyFriendRequestCoreClass> = MyFriendRequestCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", theUserID)
        do {
            let result = try context.fetch(request)
            
            if let x = result.first {
                return x.isOutbound
            }
            else {
                return false
            }
        } catch {
            return false
        }
    }


    
    
    
    
    
    
    
    
    // Update Label Functions
    
    func updateUserNameLabel(userName : String) {
        userNameLabel.text = userName
    }
    func updateUserHandleLabel(userHandle : String) {
        userHandleLabel.text = "@" + userHandle
    }
    func updateUserImageLabel(theUserID : String) {
        
        let imageRef = self.storageRef.reference(withPath: "UserProfileImages/\(theUserID).jpeg")

        self.userImageView.sd_setImage(with: imageRef, placeholderImage: UIImage(color: Constant.myBlackColor))
        
        imageRef.getMetadata { (metadataPayload, error) in
            guard let metadata = metadataPayload else { return }
            
            if let customMetadata = metadata.customMetadata {
                if customMetadata["didUpdate"] == "YES" {
                    let objCache = SDImageCache.shared()
                    objCache.clearMemory()
                    objCache.clearDisk {
                        self.userImageView.sd_setImage(with: imageRef, placeholderImage: UIImage(color: Constant.myBlackColor))
                    }
                }
            }
        }
        
    }
    
    
    
    
    
    
    
    // Miscelaneous
    
    
    
    

}




extension FriendProfileViewController: MIBlurPopupDelegate {
    
    var popupView: UIView {
        return popupContainerView ?? UIView()
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
