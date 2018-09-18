//
//  CirclePageViewController.swift
//  OASIS1
//
//  Created by Honey on 7/2/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Firebase

class CirclePageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var db : Firestore!
    var listener : ListenerRegistration!
    
    var circleID : String!
    
    var subViewControllers : [UIViewController] = []
    
    var updateLabelsDelegate: UpdateChatLabelsDelegate?
    
    
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }


    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = (UIApplication.shared.delegate as! AppDelegate).db
        
        self.delegate = self
        self.dataSource = self

        initializeCircleChatsFromFirebase()
        
        updateInCircleID(theCircleID: circleID)
    }
    
    deinit {
        print("\nCircle PageVC is DE-INIT\n")
    }
    
    
    
    
    
    
    
    
    
    // Track the current index
    var pendingIndex: Int = 0
    var currentIndex: Int = 0
    
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingIndex = subViewControllers.index(of: pendingViewControllers.first!) ?? 0
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            
            self.updateFirebaseUsersLiveArray(previousIndex: currentIndex, currentIndex: pendingIndex)
            
            currentIndex = pendingIndex
        }
    }
    
    func adjustCurrentIndex(removedIndexIs removedIndex : Int) {
        if currentIndex == removedIndex {
            if currentIndex+1 < subViewControllers.count {
                let x = currentIndex
                currentIndex = x
            }
            else if currentIndex-1 >= 0 {
                currentIndex-=1
            }
        }
        else if currentIndex > removedIndex {
            currentIndex-=1
        }
    }
    
    
    
    
    
    
    
    
    
    //PageViewController Datasource stubs
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return subViewControllers.count
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex:Int = subViewControllers.index(of: viewController) ?? 0
        if currentIndex<=0 {
            //return subViewControllers[subViewControllers.count-1]
            return nil
        }
        return subViewControllers[currentIndex-1]
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex:Int = subViewControllers.index(of: viewController) ?? 0
        if currentIndex >= subViewControllers.count-1 {
            //return subViewControllers[0]
            return nil
        }
        return subViewControllers[currentIndex+1]
    }
    
    
    func refreshPageVCDataSource() {
        self.dataSource = nil
        self.dataSource = self
        self.setViewControllers([self.subViewControllers[self.currentIndex]], direction: .forward, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    
    
    //Firebase Server Communication
    
    func initializeCircleChatsFromFirebase () {

        let docRef = db.collection("Circles").document(circleID).collection("Chats")
        
        listener = docRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            
            document.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    print("Added CIRCLE: \(diff.document.documentID)")
                    
                    let vc = NMessengerSUPERViewController()
                    vc.circleID = self.circleID
                    vc.chatID = diff.document.documentID
                    if let usersLiveList = diff.document.data()["usersLiveList"] as? [String:Date] {
                        vc.usersLiveList = usersLiveList
                        print("YRN ()")
                    }
                    
                    self.subViewControllers.append(vc)
                    
                    self.refreshPageVCDataSource()
                    
                    self.updateFirebaseUsersLiveArray(previousIndex: -1, currentIndex: self.currentIndex)
                    
                    self.updateLabelsDelegate?.updateChatLabels()
                    
                }
                if (diff.type == .removed) {
                    
                    for (index,vc) in self.subViewControllers.enumerated() {
                        let theVC = vc as! NMessengerSUPERViewController
                        if theVC.chatID == diff.document.documentID{
                            
                            if self.subViewControllers.count == 1 {
                                self.dismiss(animated: true, completion: nil)
                                break
                            }
                            self.adjustCurrentIndex(removedIndexIs: index)
                            self.subViewControllers.remove(at: index)
                            
                            self.refreshPageVCDataSource()
                            
                            self.updateFirebaseUsersLiveArray(previousIndex: -1, currentIndex: self.currentIndex)
                            
                            self.updateLabelsDelegate?.updateChatLabels()
                            
                            break
                        }
                    }
                }
                if (diff.type == .modified) {
                    
                    print("Modified ***\n")
                    
                    if let usersLiveList = diff.document.data()["usersLiveList"] as? [String:Date] {
                        
                        for (_,vc) in self.subViewControllers.enumerated() {
                            let theVC = vc as! NMessengerSUPERViewController
                            if theVC.chatID == diff.document.documentID {
                                theVC.usersLiveList = usersLiveList
                                break
                            }
                        }

                        self.updateLabelsDelegate?.updateChatLabels()
                        
                        
                    }
                }
            }
        }
    }
    func removeListener() {
        listener.remove()
    }
    
    func updateFirebaseUsersLiveArray(previousIndex : Int, currentIndex : Int) {
        
        if previousIndex > -1 {
            let initialVC = subViewControllers[previousIndex] as! NMessengerSUPERViewController
            let initialChatID = initialVC.chatID
            
            let initialRef = db.collection("Circles").document(circleID).collection("Chats").document(initialChatID!)
            let initialData = ["usersLiveList.\(Auth.auth().currentUser?.uid ?? "nil")" : FieldValue.delete()] as [String : Any]
            initialRef.updateData(initialData)
        }
        
        if currentIndex > -1 {
            let afterVC = subViewControllers[currentIndex] as! NMessengerSUPERViewController
            let afterChatID = afterVC.chatID
            
            let afterRef = db.collection("Circles").document(circleID).collection("Chats").document(afterChatID!)
            let afterData = ["usersLiveList.\(Auth.auth().currentUser?.uid ?? "nil")" : FieldValue.serverTimestamp()] as [String : Any]
            afterRef.updateData(afterData)
        }
        
    }
    
    func updateInCircleID(theCircleID : String) {
        db.collection("User-Profile").document(Auth.auth().currentUser?.uid ?? "nil").setData(["inCircleID" : theCircleID], merge: true)
    }
    
    
    
    
    

}




protocol UpdateChatLabelsDelegate : class {
    func updateChatLabels()
}
