//
//  ManageProfileViewController.swift
//  OASIS1
//
//  Created by Honey on 8/20/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import YPImagePicker
import Firebase
import CoreData
import SDWebImage

class ManageProfileViewController: UIViewController, CoreFireMyProfileUpdatedProtocol {
    
    
    // Core Fire My Profile Updated Delegate
    
    func CoreFireMyProfileUpdated() {
        if ghostSwitch.isOn {
            setUpGhostLabels()
        } else {
            setUpNormalLabels()
        }
    }
    
    
    
    
    @IBOutlet weak var ghostSwitch: UISwitch!
    
    @IBOutlet weak var profileContainerView: UIView!
    
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userHandleLabel: UILabel!
    
    
    
    var storageRef : Storage = (UIApplication.shared.delegate as! AppDelegate).storageRef
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let cfMyProfile = CoreFireMyProfile.sharedInstance
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ghostSwitch.isOn = isGhostEnabled()
        
        cfMyProfile.delegate = self
        
        setUpView()
        
        setUpGestures()
    }
    
    
    func setUpView() {
        
        ghostSwitch.tintColor = UIColor.darkGray
        ghostSwitch.thumbTintColor = Constant.myBlackColor
        ghostSwitch.onTintColor = Constant.myGrayColor
        
        if isGhostEnabled() {
            setUpGhostView()
            setUpGhostLabels()
        } else {
            setUpNormalView()
            setUpNormalLabels()
        }
        
        
        let maskLayer = CAShapeLayer()
        let maskPath: UIBezierPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: ([.topLeft, .topRight]), cornerRadii: CGSize(width: 10.0, height: 10.0))
        maskLayer.frame = view.bounds
        maskLayer.path = maskPath.cgPath
    }
    
    func setUpGestures() {
        let tap1 = UITapGestureRecognizer(target: self,
                                         action: #selector(handleUserImageViewTap(sender:)))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(tap1)
        
        
        let tap2 = UITapGestureRecognizer(target: self,
                                          action: #selector(handleUsernameLabelTap(sender:)))
        userNameLabel.isUserInteractionEnabled = true
        userNameLabel.addGestureRecognizer(tap2)
    }
    
    
    
    
    
    
    
    // MARK:- Load Different Views
    
    
    func setUpNormalView() {
//        self.view.backgroundColor = Constant.myBlackColor
//
//        profileContainerView.backgroundColor = UIColor(red:0.11, green:0.63, blue:0.95, alpha:1.0)
//        profileContainerView.layer.borderColor = Constant.myWhiteColor.cgColor
//        profileContainerView.layer.borderWidth = 3.0
//
//        userImageView.layer.cornerRadius = 10
//        userImageView.clipsToBounds = true
//        //userImageView.image = UIImage(color: Constant.myBlackColor)
//        userImageView.layer.borderColor = Constant.myWhiteColor.cgColor
//        userImageView.layer.borderWidth = 2.0
//
//        userNameLabel.textColor = Constant.myWhiteColor
//        userHandleLabel.textColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        
        self.view.backgroundColor = Constant.myWhiteColor
        
        profileContainerView.backgroundColor = Constant.myTwitterBlue
        profileContainerView.layer.borderColor = Constant.myTwitterBlue.cgColor
        profileContainerView.layer.borderWidth = 3.0
        
        userImageView.layer.cornerRadius = 10
        userImageView.clipsToBounds = true
        userImageView.layer.borderColor = UIColor.white.cgColor
        userImageView.layer.borderWidth = 0.0
        
        userNameLabel.textColor = UIColor.white
        userHandleLabel.textColor = UIColor.white

        
        profileContainerView.layer.shadowColor = UIColor.black.cgColor
        profileContainerView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        profileContainerView.layer.shadowOpacity = 0.40
        profileContainerView.layer.shadowRadius = 4.0
        
    }
    
    func setUpGhostView() {
        self.view.backgroundColor = Constant.myBlackColor
        
        profileContainerView.backgroundColor = Constant.myBlackColor
        profileContainerView.layer.borderColor = Constant.myGrayColor.cgColor
        profileContainerView.layer.borderWidth = 3.0
        
        userImageView.layer.cornerRadius = 10
        userImageView.clipsToBounds = true
        userImageView.layer.borderColor = Constant.myGrayColor.cgColor
        userImageView.layer.borderWidth = 2.0
        
        userNameLabel.textColor = Constant.myGrayColor
        userHandleLabel.textColor = Constant.myGrayColor
    }
    
    func setUpNormalLabels() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        let request : NSFetchRequest<MyProfileCoreClass> = MyProfileCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", myUID)
        do {
            let result = try context.fetch(request)
            
            if let x = result.first {
                updateUserNameLabel(userName: x.userName!)
                updateUserHandleLabel(userHandle: x.userHandle!)
                updateUserImageLabel(theUserID: x.userID!)
            } else {
                updateUserNameLabel(userName: "error")
                updateUserHandleLabel(userHandle: "error")
                updateUserImageLabel(theUserID: "error")
            }
        } catch {
            updateUserNameLabel(userName: "error")
            updateUserHandleLabel(userHandle: "error")
            updateUserImageLabel(theUserID: "error")
        }
    }
    
    func setUpGhostLabels() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        let request : NSFetchRequest<MyProfileCoreClass> = MyProfileCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", myUID)
        do {
            let result = try context.fetch(request)
            
            if let x = result.first {
                updateUserHandleLabel(userHandle: "ghost")
                updateUserNameLabel(userName: x.ghostName!)
                
                let dataDecoded:NSData = NSData(base64Encoded: Constant.ghostAvatarString, options: NSData.Base64DecodingOptions(rawValue: 0))!
                let decodedimage:UIImage = UIImage(data: dataDecoded as Data)!
                
                userImageView.image = decodedimage
                
            } else {
                updateUserNameLabel(userName: "")
                updateUserHandleLabel(userHandle: "")
                updateUserImageLabel(theUserID: "")
            }
        } catch {
            updateUserNameLabel(userName: "")
            updateUserHandleLabel(userHandle: "")
            updateUserImageLabel(theUserID: "")
        }
    }
    
    
    //MARK: - Update Label Functions
    
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

            let metadataPayload = StorageMetadata()
            metadataPayload.customMetadata = [
                "didUpdate": "NO"
            ]
            imageRef.updateMetadata(metadataPayload, completion: nil)

        }
        
    }
    
    
    
    
    // MARK:- User Tap Functions
    
    @objc func handleUsernameLabelTap(sender: UIGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChangeProfileNameViewController") as! ChangeProfileNameViewController
        vc.isForGhost = ghostSwitch.isOn
        MIBlurPopup.show(vc, on: self)
    }
    
    
    @objc func handleUserImageViewTap(sender: UIGestureRecognizer) {
        
        if isGhostEnabled() {
            return
        }
        
        var config = YPImagePickerConfiguration()
        config.hidesStatusBar = false
        config.showsFilters = false
        config.library.mediaType = .photo
        config.hidesStatusBar = false
        config.library.maxNumberOfItems = 1
        config.library.numberOfItemsInRow = 3
        config.library.spacingBetweenItems = 2
        config.library.onlySquare  = true
        config.onlySquareImagesFromCamera = true
        config.colors.photoVideoScreenBackground = Constant.myBlackColor
        config.wordings.next = "Upload"
        
        let picker = YPImagePicker(configuration: config)
        
        picker.didFinishPicking { [unowned picker] items, _ in
            if let photo = items.singlePhoto {
                let img = photo.image.imageScaled(to: CGSize(width: 300.0, height: 300.0))
                self.uploadProfileImage(img: img!)
            }
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
    
    
    func uploadProfileImage(img : UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var data = NSData()
        data = UIImageJPEGRepresentation(img, 1.0)! as NSData
        let mountainsRef = storageRef.reference(withPath: "UserProfileImages/\(uid).jpeg")
        let metadataPayload = StorageMetadata()
        metadataPayload.customMetadata = [
            "didUpdate": "YES"
        ]
        let _ = mountainsRef.putData(data as Data, metadata: metadataPayload) { (met, err) in
            self.updateUserImageLabel(theUserID: uid)
        }
        
        
        
    }
    
    
    
    
    // MARK:- Switcher Switched
    
    
    @IBAction func ghostSwitchSwitched(_ sender: UISwitch) {
        if sender.isOn {
            saveGhostSwitch(isOn: true)
            self.setUpGhostLabels()
            UIView.animate(withDuration: 0.5) {
                self.setUpGhostView()
            }
        } else {
            saveGhostSwitch(isOn: false)
            self.setUpNormalLabels()
            UIView.animate(withDuration: 0.5) {
                self.setUpNormalView()
            }
        }
    }
    
    
    
    // MARK:- Load & Save isGhostOn to pList
    
    func isGhostEnabled() -> Bool {
        if let status = UserDefaults.standard.object(forKey: "isGhostOn") as? Bool {
            return status
        } else {
            return false
        }
    }
    
    func saveGhostSwitch(isOn : Bool) {
        if isOn {
            UserDefaults.standard.set(true, forKey: "isGhostOn")
        } else {
            UserDefaults.standard.set(false, forKey: "isGhostOn")
        }
    }

    
}
