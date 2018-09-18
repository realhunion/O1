//
//  CoreFireMyProfile.swift
//  OASIS1
//
//  Created by Honey on 8/31/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import Firebase
import CoreData

class CoreFireMyProfile {
    
    
    static let sharedInstance: CoreFireMyProfile = { return CoreFireMyProfile() }()
    
    
    var delegate:CoreFireMyProfileUpdatedProtocol?
    
    
    var db : Firestore = (UIApplication.shared.delegate as! AppDelegate).db
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var profileListener : ListenerRegistration?
    
    
    
    
    init() {
        print("initiiiiii CORE MY PROFILE MODEL\n\n")
        
    }
    
    
    func deleteAllData() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MyProfileCoreClass")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do { try context.execute(request) }
        catch { print("Error: \(error)") }
    }
    
    
    
    
    func startUserbaseFirebaseConnection (myUID : String) {
        
        profileListener = db.collection("User-Profile").document(myUID).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            let myUserID = document.documentID
            if let userName = document.data()?["userName"] as? String, let userHandle = document.data()?["userHandle"] as? String {
                if let ghostName = document.data()?["ghostName"] as? String {
                    self.updateCoreData(theUserID: myUserID, theUserName: userName, theUserHandle: userHandle, theUserGhostName: ghostName)
                } else {
                    self.updateCoreData(theUserID: myUserID, theUserName: userName, theUserHandle: userHandle)
                }
            }
        }
    }
    
    
    func removeListener() {
        if let profileListenr = profileListener {
            profileListenr.remove()
        }
    }
    func shutDown() {
        removeListener()
    }
    
    
    
    
    func updateCoreData(theUserID : String, theUserName : String, theUserHandle : String, theUserGhostName : String = "Ghost Name") {
        
        let request : NSFetchRequest<MyProfileCoreClass> = MyProfileCoreClass.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", theUserID)
        do {
            let result = try context.fetch(request)
            
            if let x = result.first {
                x.userID = theUserID
                x.userName = theUserName
                x.userHandle = theUserHandle
                x.ghostName = theUserGhostName
            }
            else {
                let x = MyProfileCoreClass(context: context)
                x.userID = theUserID
                x.userName = theUserName
                x.userHandle = theUserHandle
                x.ghostName = theUserGhostName
            }
            saveCoreData()
            delegate?.CoreFireMyProfileUpdated()
            
        } catch {
            print("\nFailed..\(theUserID)")
        }
        
    }
    
    
    
    func saveCoreData() {
        do { try context.save() }
        catch { print("Error: \(error)") }
    }
    
    
    
    
    
    
    
}



protocol CoreFireMyProfileUpdatedProtocol:class {
    func CoreFireMyProfileUpdated()
}
