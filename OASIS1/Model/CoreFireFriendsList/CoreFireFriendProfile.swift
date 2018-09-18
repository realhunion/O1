//
//  CoreFireFriendProfile.swift
//  OASIS1
//
//  Created by Honey on 7/17/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import Firebase
import CoreData

class CoreFireFriendProfile {
    
    var delegate:FriendProfileUpdatedProtocol?
    
    var listener : ListenerRegistration!
    
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var friendUserID : String
    init(theFriendUserID : String) {
        friendUserID = theFriendUserID
        startFriendFirebaseConnection()
    }
    

    
    
    func startFriendFirebaseConnection () {
        
        listener = db.collection("User-Profile").document(friendUserID)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                if let theData = document.data() {
                    if let userName = theData["userName"] as? String, let userActive = theData["userActive"] as? Bool {
                        self.updateCoreData(theUserID: document.documentID, theUserName: userName, theUserActive: userActive)
                    }
                }
        }
    }
    
    func removeListener() {
        listener.remove()
    }
    
    
    
    
    func updateCoreData(theUserID : String, theUserName : String, theUserActive : Bool) {
        
        let request : NSFetchRequest<MyFriendCoreClass> = MyFriendCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", theUserID)
        do {
            let result = try context.fetch(request)
            
            
            if let x = result.first {
                x.userID = theUserID
                x.userName = theUserName
                x.userActive = theUserActive
            }
            else {
                let x = MyFriendCoreClass(context: context)
                x.userID = theUserID
                x.userName = theUserName
                x.userActive = theUserActive
                x.isSelected = false
                x.timesSelected = 0
            }
            saveCoreData()
            delegate?.FriendProfileUpdated()
            
        } catch {
            print("\nFailed..\(theUserID)")
        }
        
    }
    
    
    
    
    
    
    func saveCoreData() {
        do { try context.save() }
        catch { print("Error: \(error)") }
    }
    
    
}


protocol FriendProfileUpdatedProtocol {
    func FriendProfileUpdated()
}
