//
//  File.swift
//  OASIS1
//
//  Created by Honey on 7/17/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import CoreData
import Firebase

class InviteFriendsTableViewController: UITableViewController, CoreFriendsListUpdatedProtocol {
    
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    
    var myFriendsArray : [MyFriendCoreClass] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let cfFriendsList = CoreFireFriendsList.sharedInstance
    
    var circleID : String = "lol"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cfFriendsList.delegate = self
        loadFriendsList()
        sortFriendsListArray()
        
    }
    
    deinit {
        print("invite friends de-init")
    }

    func deInitNeccessities() {
        cfFriendsList.delegate = nil
        myFriendsArray = []
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        deInitNeccessities()
        super.dismiss(animated: flag, completion: completion)
    }
    
    
    
    func CoreFriendsListUpdated() {
        sortFriendsListArray()
        tableView.reloadData()
    }
    
    func sendCircleInvite(friendUID : String, circleID : String) {
        let myUserID = Auth.auth().currentUser?.uid
        let payload : [String:Any] = [
            "inviterName": "Bobby",
            "inviterUID": myUserID,
            "invitedUID": friendUID,
            "circleID": circleID
        ]
        db.collection("Request-CircleInvite").document().setData(payload)
    }
    
    
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myFriendsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(myFriendsArray.count)
        let cell = Bundle.main.loadNibNamed("InviteFriendsTableViewCell", owner: self, options: nil)?.first as! InviteFriendsTableViewCell
        
        cell.tintColor = UIColor.white
        cell.selectionStyle = .none
        
        cell.fullnameLabel.text = myFriendsArray[indexPath.row].userName
        if myFriendsArray[indexPath.row].isSelected == true {
            cellSelected(cell: cell)
        } else {
            cellUnSelected(cell: cell)
        }
        
        return cell
        
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = Bundle.main.loadNibNamed("InviteFriendsTableViewCell", owner: self, options: nil)?.first as! InviteFriendsTableViewCell
        return cell.bounds.height
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? InviteFriendsTableViewCell {
            
            if myFriendsArray[indexPath.row].isSelected == false {
                cellSelected(cell: cell)
                myFriendsArray[indexPath.row].isSelected = true
                myFriendsArray[indexPath.row].timesSelected += 1
                let friendUID = myFriendsArray[indexPath.row].userID!
                sendCircleInvite(friendUID: friendUID, circleID: self.circleID)
            }
        }
        
        saveMyFriendsList()
    }
    
    
    
    
    
    
    
    //SORTING Function
    func sortFriendsListArray() {
        
        myFriendsArray = myFriendsArray.sorted(by: { (s1, s2) -> Bool in
            if s1.timesSelected > s2.timesSelected {
                return true //this will return true: s1 is priority, s2 is not
            }
            if s1.timesSelected < s1.timesSelected {
                return false //this will return false: s2 is priority, s1 is not
            }
            if s1.timesSelected == s2.timesSelected {
                
                let result = s1.userName!.caseInsensitiveCompare(s2.userName!)
                return (result == ComparisonResult.orderedAscending) // stringOne < stringTwo

            }
            return false
        })
    }
    

    
    
    
    
    
    
    
    // Cell Selected / Unselected UI
    
    func cellSelected(cell : InviteFriendsTableViewCell) {
        cell.accessoryType = .checkmark
        cell.fullnameLabel.textColor = UIColor.white
        cell.backgroundColor = UIColor(red:0.96, green:0.14, blue:0.35, alpha:1.0)
    }
    
    func cellUnSelected(cell : InviteFriendsTableViewCell) {
        cell.accessoryType = .none
        cell.fullnameLabel.textColor = UIColor.black
        cell.backgroundColor = UIColor.white
    }

    
    
    // Core Data Save / Load functions
    
    func saveMyFriendsList() {
        do {
            try context.save()
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func loadFriendsList() {
        let request : NSFetchRequest<MyFriendCoreClass> = MyFriendCoreClass.fetchRequest()
        do {
            myFriendsArray = try context.fetch(request)
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    
}
