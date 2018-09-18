//
//  AppDelegate.swift
//  OASIS1
//
//  Created by Honey on 6/26/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseInstanceID
import CoreData
import CoreLocation
import Sparrow
import UserNotifications



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    var db: Firestore!
    var ref: DatabaseReference!
    var storageRef:Storage!
    


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let v = UIViewController()
        v.view.backgroundColor = UIColor.black
        self.window?.rootViewController = v
        self.window?.makeKeyAndVisible()
    
        
        configureMyFirebase()
        ref = Database.database().reference()
        storageRef = Storage.storage()
        
       
        updateUserLiveStatus()
    
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        let _ = VCSwitcherModel.sharedInstance
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        if let chatVC = self.window?.rootViewController?.presentedViewController as? CircleChatViewController {
            chatVC.dismissRulesInviteFriendsVC()
            chatVC.endPan(withProgress: 1.0)
            chatVC.dismiss(animated: false, completion: nil)
        }
        if let theVC = self.window?.rootViewController?.presentedViewController as? DeckPresentedViewController {
            theVC.endPan(withProgress: 1.0)
            theVC.dismiss(animated: false, completion: nil)
        }
        self.window?.rootViewController?.dismiss(animated: false, completion: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        updateUserOnOffline(isOnline: false)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        updateUserOnOffline(isOnline: true)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    
    
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OASIS1")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    
    
    
    
    
    
    // MARK: - Initialize Firebase Database
    
    func configureMyFirebase() {
        FirebaseApp.configure()
        db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        Firestore.firestore().settings = settings
    }
    
    
    func updateUserBaseFCMToken(fcmToken : String) {
        //SetOptions.merge()
        if let myUID = Auth.auth().currentUser?.uid {
            db.collection("User-Base").document(myUID).setData([ "fcmToken": fcmToken ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("\n**** New Token Generated.\n\(fcmToken)")
        updateUserBaseFCMToken(fcmToken: fcmToken)
        //Make sure we still write token if new registration or if user is logging back in. Preferably from login or registration screen, write
        
    }
    
    
    func updateUserOnOffline(isOnline : Bool) {
        if isOnline {
            Database.database().goOnline()
        }
        else {
            Database.database().goOffline()
        }
    }
    
    
    func updateUserLiveStatus() {
        
        guard let myUID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userStatusDatabaseRef = Database.database().reference(withPath: "status/\(myUID)")
        
        // We'll create two constants which we will write to
        // the Realtime database when this device is offline
        // or online.
        let isOfflineForDatabase = [
            "state" : "offline",
            "last_changed" : ServerValue.timestamp()
            ] as [String : Any]
        
        let isOnlineForDatabase = [
            "state" : "online",
            "last_changed" : ServerValue.timestamp()
            ] as [String : Any]
        
        
        
        let userStatusFirestoreRef = db.document("User-Profile/\(myUID)")
        
        // Firestore uses a different server timestamp value, so we'll
        // create two more constants for Firestore state.
        let isOfflineForFirestore = [
            "userActive" : false,
            "lastSeen" : FieldValue.serverTimestamp()
            ] as [String : Any]
        
        let isOnlineForFirestore = [
            "userActive" : true,
            "lastSeen" : FieldValue.serverTimestamp()
            ] as [String : Any]
        
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        connectedRef.observe(.value, with: { snapshot in
            // only handle connection established (or I've reconnected after a loss of connection)
            guard let connected = snapshot.value as? Bool, connected else {
                
                userStatusFirestoreRef.setData(isOfflineForFirestore, merge: true)
                return
                
            }
            
            
            userStatusDatabaseRef.onDisconnectSetValue(isOfflineForDatabase, withCompletionBlock: { (error, ref) in
                userStatusDatabaseRef.setValue(isOnlineForDatabase)
                userStatusFirestoreRef.setData(isOnlineForFirestore, merge: true)
            })
        
        })
        
        
        
        

    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // Mark: - Remote Notifiicaitons
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("bang bang")
        if let u = userInfo["textGiven"] as? String {
            print("\(u)")
        }
    }
    
    
    
    

}


////TESTING
////TESTING
////TESTING
////TESTING
////TESTING
////TESTING
////TESTING
////TESTING
////TESTING
////TESTING
