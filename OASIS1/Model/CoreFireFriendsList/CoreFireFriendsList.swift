//
//  CoreFireFriendList.swift
//  OASIS1
//
//  Created by Honey on 7/17/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import Firebase
import CoreData

class CoreFireFriendsList : FriendProfileUpdatedProtocol {
    
    
    // Create a singleton instance
    static let sharedInstance: CoreFireFriendsList = { return CoreFireFriendsList() }()
    
    
    
    var delegate:CoreFriendsListUpdatedProtocol?
    
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var listener : ListenerRegistration?
    let myUserID = Auth.auth().currentUser?.uid
    
    var friendMonitorArray : [String : CoreFireFriendProfile] = [:]
    
    
    
    init() {
        print("initiiiiii COREFIRE MODEL\n\n")
        
    }
    
    
    func deleteAllData() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MyFriendCoreClass")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do { try context.execute(request) }
        catch { print("Error: \(error)") }
    }
    
    
    
    
    func startUserbaseFirebaseConnection (myUID : String) {
        
        listener = db.collection("User-Base").document(myUID).collection("MyFriends").addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error Connection to Userbase Friends List...\n\n: \(error!)")
                return
            }
            document.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    print("Added Friend: \(diff.document.documentID)")
                    let friendUserID = diff.document.documentID
                    self.monitorFriend(friendUID: friendUserID)
                }
                if (diff.type == .removed) {
                    print("Removed Friend: \(diff.document.documentID)")
                    let friendUserID = diff.document.documentID
                    self.stopMonitorFriend(friendUID: friendUserID)
                    self.removeFriendCoreData(friendUID: friendUserID)
                }
            }
        }
    }
    
    func removeListener() {
        if let listenr = listener {
            listenr.remove()
        }
    }
    func shutDown() {
        removeListener()
        for (_,y) in friendMonitorArray {
            y.removeListener()
            y.delegate = nil
        }
        friendMonitorArray = [:]
    }
    
    
    
    
    func monitorFriend(friendUID : String) {
        let x = CoreFireFriendProfile(theFriendUserID: friendUID)
        x.delegate = self as FriendProfileUpdatedProtocol
        friendMonitorArray[friendUID] = x
    }
    func stopMonitorFriend(friendUID : String) {
        if let x = friendMonitorArray[friendUID] {
            x.removeListener()
            friendMonitorArray[friendUID] = nil
        }
    }
    func removeFriendCoreData(friendUID : String) {
        let request : NSFetchRequest<MyFriendCoreClass> = MyFriendCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", friendUID)
        do {
            let result = try context.fetch(request)
            for x in result {
                context.delete(x)
                delegate?.CoreFriendsListUpdated()
            }
        } catch { print("\nFailed..\(friendUID)") }
    }
    
    
    
    
    
    func FriendProfileUpdated() {
        delegate?.CoreFriendsListUpdated()
    }
    
    
}



protocol CoreFriendsListUpdatedProtocol:class {
    func CoreFriendsListUpdated()
}
