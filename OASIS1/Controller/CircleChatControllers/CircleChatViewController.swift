//
//  CircleChatViewController.swift
//  OASIS1
//
//  Created by Honey on 7/2/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import CHIPageControl
import CoreData

class CircleChatViewController: DeckPresentedViewController, UIPopoverPresentationControllerDelegate, UpdateChatLabelsDelegate {
    
    
    var circleID : String!
    var circlePageVCRef : CirclePageViewController?
    
    
    
    
    @IBOutlet weak var inviteButton: UIButton!
    
    @IBOutlet weak var numUsersLiveLabel: UILabel!
    
    @IBOutlet weak var pageControlLabel: CHIPageControlAleppo!
    
    
    
    
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inviteButton.layer.cornerRadius = 8.0
        if isGhostEnabled() {
            inviteButton.backgroundColor = UIColor.gray
            inviteButton.isEnabled = false
        }
        
    }
    deinit {
        print("\n\(circleID ?? ".") Circle Chat VC is DE-INIT\n")
    }
    
    
    
    // Check is ghost enabled
    func isGhostEnabled() -> Bool {
        if let status = UserDefaults.standard.object(forKey: "isGhostOn") as? Bool {
            return status
        } else {
            return false
        }
    }
    
    
    
    // Functions needed for proper de-init
    
    func deInitNecessities() {

        if let pageVCRef = circlePageVCRef {           
            
            pageVCRef.removeListener()
            pageVCRef.updateLabelsDelegate = nil
            for (i,vc) in pageVCRef.subViewControllers.enumerated() {
                let thisVC = vc as! NMessengerSUPERViewController
                if thisVC.initialMessageLoadingState == true {
                    thisVC.removeListener()
                }
                pageVCRef.updateFirebaseUsersLiveArray(previousIndex: i, currentIndex: -1)
                
                pageVCRef.updateInCircleID(theCircleID: "")
                
                thisVC.messengerView.delegate = nil
                
                thisVC.messengerView.clearALLMessages()
            }
            pageVCRef.subViewControllers = []
            circlePageVCRef = nil
        }
        
        
        //Updating isSelected to false on all userprofiles in CoreData. FIX: possible workaround
        var myFriendsArray : [MyFriendCoreClass] = []
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request : NSFetchRequest<MyFriendCoreClass> = MyFriendCoreClass.fetchRequest()
        do { myFriendsArray = try context.fetch(request) }
        catch { print("Error: \(error)") }
        for f in myFriendsArray {
            f.isSelected = false
        }
        do { try context.save() }
        catch { print("Error: \(error)") }
        
        
        //FIX: memory deallocation. deallocated when new one presented. not right wen dismissed.
        //self.delegate = nil
        //self.transitioningDelegate = nil
    }
    
    
    func dismissRulesInviteFriendsVC() {
        if let modal = self.presentedViewController as? InviteFriendsTableViewController {
            modal.deInitNeccessities()
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        
        dismissRulesInviteFriendsVC()

        super.dismiss(animated: flag, completion: completion)
    }
    

    
    
    
    
    
    

    
    
    
    // CirclePageVC Delegate for updating labels
    
    func updateChatLabels() {
        
        if let pageVCRef = circlePageVCRef {
            
            let cIndex = pageVCRef.currentIndex
            
            let vc = pageVCRef.subViewControllers[cIndex] as! NMessengerSUPERViewController
            let numUsersLive = vc.usersLiveList.count
            
            numUsersLiveLabel.text = "# \(numUsersLive)"
            
            let numChats = pageVCRef.subViewControllers.count
            
            pageControlLabel.numberOfPages = numChats
            pageControlLabel.set(progress: cIndex, animated: true)
        }
        //FIX: Title editable perhaps
    }
    
    
    
    
    
    

    

    
    
    // Prepare for Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCircleChatContainer" {
            let destination = segue.destination as! CirclePageViewController
            destination.circleID = self.circleID
            destination.updateLabelsDelegate = self
            self.circlePageVCRef = destination
        }
        
        if segue.identifier == "goToInviteFriendsVC" {
            let destination = segue.destination as! InviteFriendsTableViewController
            destination.modalPresentationStyle = .popover
            destination.modalPresentationStyle = .overCurrentContext
            destination.popoverPresentationController?.delegate = self
            destination.popoverPresentationController?.sourceRect = inviteButton.bounds
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        print("DID DISMISS POPOVER.")
        
    }
    

    
    
    
    
    
    

}

