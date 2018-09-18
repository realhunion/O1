//
//  CoreFireFriendRequests.swift
//  OASIS1
//
//  Created by Honey on 8/15/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import Firebase
import CoreData

class CoreFireFriendRequests {
    
    
    static let sharedInstance: CoreFireFriendRequests = { return CoreFireFriendRequests() }()
    
    
    var delegate:CoreFriendRequestsUpdatedProtocol?
    
    
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var listener : ListenerRegistration?
    let myUserID = Auth.auth().currentUser?.uid ?? "nil"
    
    
    
    
    init() {
        print("initiiiiii CORE FRIENDREQUEST MODEL\n\n")
        
    }
    
    
    func deleteAllData() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MyFriendRequestCoreClass")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do { try context.execute(request) }
        catch { print("Error: \(error)") }
    }
    
    
    
    
    func startUserbaseFirebaseConnection (myUID : String) {
        
        listener = db.collection("User-Base").document(myUID).collection("MyFriendRequests").addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error Connection to Userbase Friends List...\n\n: \(error!)")
                return
            }
            document.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    print("Added Friend Request: \(diff.document.documentID)")
                    let friendUserID = diff.document.documentID
                    if let userName = diff.document.data()["userName"] as? String, let isOutbound = diff.document.data()["isOutbound"] as? Bool {
                        if let hasSeen = diff.document.data()["hasSeen"] as? Bool {
                            self.updateCoreData(theUserID: friendUserID, theUserName: userName, isItOutbound: isOutbound, isHasSeen: hasSeen)
                        } else {
                            self.updateCoreData(theUserID: friendUserID, theUserName: userName, isItOutbound: isOutbound)
                        }
                    }

                }
                if (diff.type == .modified) {
                    let friendUserID = diff.document.documentID
                    if let userName = diff.document.data()["userName"] as? String, let isOutbound = diff.document.data()["isOutbound"] as? Bool {
                        if let hasSeen = diff.document.data()["hasSeen"] as? Bool {
                            self.updateCoreData(theUserID: friendUserID, theUserName: userName, isItOutbound: isOutbound, isHasSeen: hasSeen)
                        } else {
                            self.updateCoreData(theUserID: friendUserID, theUserName: userName, isItOutbound: isOutbound)
                        }
                    }
                }
                if (diff.type == .removed) {
                    print("Removed Friend Request: \(diff.document.documentID)")
                    let friendUserID = diff.document.documentID
                    self.removeFriendRequestCoreData(friendUID: friendUserID)
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
    }
    
    
    
    
    func updateCoreData(theUserID : String, theUserName : String, isItOutbound : Bool, isHasSeen : Bool = true) {
        
        let request : NSFetchRequest<MyFriendRequestCoreClass> = MyFriendRequestCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", theUserID)
        do {
            let result = try context.fetch(request)
            
            if let x = result.first {
                x.userID = theUserID
                x.userName = theUserName
                x.isOutbound = isItOutbound
                x.hasSeen = isHasSeen
            }
            else {
                let x = MyFriendRequestCoreClass(context: context)
                x.userID = theUserID
                x.userName = theUserName
                x.isOutbound = isItOutbound
                x.hasSeen = isHasSeen
            }
            saveCoreData()
            delegate?.CoreFriendRequestsUpdated()
            
        } catch {
            print("\nFailed..\(theUserID)")
        }
        
    }
    
    func saveCoreData() {
        do { try context.save() }
        catch { print("Error: \(error)") }
    }
    
    
    
    
    func removeFriendRequestCoreData(friendUID : String) {
        let request : NSFetchRequest<MyFriendRequestCoreClass> = MyFriendRequestCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", friendUID)
        do {
            let result = try context.fetch(request)
            for x in result {
                context.delete(x)
                delegate?.CoreFriendRequestsUpdated()
            }
        } catch { print("\nFailed..\(friendUID)") }
    }
    
    
    

    
    
    
}



protocol CoreFriendRequestsUpdatedProtocol:class {
    func CoreFriendRequestsUpdated()
}
