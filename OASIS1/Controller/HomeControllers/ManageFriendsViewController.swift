//
//  ManageFriendsViewController.swift
//  OASIS1
//
//  Created by Honey on 8/11/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class ManageFriendsViewController: UICollectionViewController, CoreFriendsListUpdatedProtocol, CoreFriendRequestsUpdatedProtocol {
    
    
    
    //Self Delegate
    var delegate:FriendManagerProfileUpdated?
    
    
    //Protocol
    func CoreFriendsListUpdated() {
        guard let theCollectionView = collectionView else { return }
        
        loadFriendsList()
        sortFriendsListArray()
        
        theCollectionView.reloadData()
        let indexPaths = theCollectionView.indexPathsForVisibleItems
        theCollectionView.reloadItems(at: indexPaths)
        
        delegate?.friendProfileUpdated()
    }
    
    func CoreFriendRequestsUpdated() {
        guard let theCollectionView = collectionView else { return }
        
        loadFriendRequests()
        sortFriendRequestsArray()
        
        theCollectionView.reloadData()
        let indexPaths = theCollectionView.indexPathsForVisibleItems
        theCollectionView.reloadItems(at: indexPaths)
        
        delegate?.friendProfileUpdated()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("View did appear")
    }
    
    
    
    //Static let constants
    let sectionInsets = UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
    let itemsPerSection: Int = 3
    
    
    //Variables
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var myFriendsArray : [MyFriendCoreClass] = []
    let cfFriendsList = CoreFireFriendsList.sharedInstance
    
    var myFriendRequestsArray : [MyFriendRequestCoreClass] = []
    let cfFriendRequests = CoreFireFriendRequests.sharedInstance
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cfFriendsList.delegate = self
        self.loadFriendsList()
        self.sortFriendsListArray()
        cfFriendRequests.delegate = self
        self.loadFriendRequests()
        self.sortFriendRequestsArray()
        
        self.setUpView()
        
        self.collectionView?.register(UINib(nibName: "ManageFriendsCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: reuseIdentifier)
        
        self.collectionView?.backgroundColor = Constant.myWhiteColor
        

    }
    
    deinit {
        print("Friend Manager VC de-init")
    }
    
    
    // MARK :- Set up View
    
    func setUpView() {
        
        let maskLayer = CAShapeLayer()
        let maskPath: UIBezierPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: ([.topLeft, .topRight]), cornerRadii: CGSize(width: 10.0, height: 10.0))
        maskLayer.frame = view.bounds
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        view.layer.masksToBounds = true
        
        //view.addInnerShadow(onSide: .top, shadowColor: UIColor.black, shadowSize: 3.5, shadowOpacity: 0.5)
        
        
    }
    
    
    
    
    // MARK:- Load & Sort Friends List
    
    func loadFriendsList() {
        let request : NSFetchRequest<MyFriendCoreClass> = MyFriendCoreClass.fetchRequest()
        do {
            myFriendsArray = try context.fetch(request)
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func sortFriendsListArray() {
        
        myFriendsArray = myFriendsArray.sorted(by: { (s1, s2) -> Bool in
            let result = s1.userName!.caseInsensitiveCompare(s2.userName!)
            return (result == ComparisonResult.orderedAscending) // stringOne < stringTwo
        })
    }
    
    
    // MARK:- Load & Sort Friend Requests
    
    func loadFriendRequests() {
        let request : NSFetchRequest<MyFriendRequestCoreClass> = MyFriendRequestCoreClass.fetchRequest()
        do {
            myFriendRequestsArray = try context.fetch(request)
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func sortFriendRequestsArray() {
        
        myFriendRequestsArray = myFriendRequestsArray.sorted(by: { (s1, s2) -> Bool in
            let result = s1.userName!.caseInsensitiveCompare(s2.userName!)
            return (result == ComparisonResult.orderedAscending) // stringOne < stringTwo
        })
    }
    
    
    
    
    
    
    
    
    
    // MARL:- Return object at index
    
    
    func returnIndex(row : Int, section : Int) -> Int {
        let index = row + (itemsPerSection * section)
        return index
    }
    
    func isValidIndex(row : Int, section : Int) -> Bool {
        let index = returnIndex(row: row, section: section)
        return index < (1 + myFriendsArray.count + myFriendRequestsArray.count)
    }
    
    
    
    
    
    
    
    
    
    
    

    // MARK:- UICollectionView Data Source

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        var extraSections = 4
        if (myFriendsArray.count + myFriendRequestsArray.count + 1) % itemsPerSection != 0 {
            extraSections += 1
        }
        let numSections = Int(floor(Double((myFriendsArray.count + myFriendRequestsArray.count) / itemsPerSection)))
        return numSections + extraSections
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return itemsPerSection
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ManageFriendsCollectionViewCell
    
        // Configure the cell
        
        cell.layer.borderWidth = 1.0
        cell.layer.cornerRadius = 8.0
        
        
        let index = returnIndex(row: indexPath.row, section: indexPath.section)
        
        
        if index == 0 {
//            cell.nameLabel.text = "Add a Friend"
//            cell.arrowLabel.text = "□"
//            let colorIndex = index % colorArray.count
//            cell.backgroundColor = colorArray[colorIndex] ?? UIColor.flatBlack()
//            cell.layer.borderColor = colorArray[colorIndex]?.cgColor ?? UIColor.flatBlack()?.cgColor
            cell.nameLabel.text = "Add a Friend"
            cell.nameLabel.textColor = UIColor.flatBlack()
            cell.arrowLabel.text = ""
            cell.arrowLabel.textColor = UIColor.flatBlack()
            cell.backgroundColor = Constant.myWhiteColor
            cell.layer.borderColor = UIColor.flatBlack()?.cgColor
            
        }
        else if index-1 < myFriendRequestsArray.count {
            cell.nameLabel.text = myFriendRequestsArray[index-1].userName
            cell.arrowLabel.text = "□"
            let colorIndex = index % colorArray.count
            cell.backgroundColor = UIColor.flatBlack()
            cell.layer.borderColor = UIColor.flatBlack()?.cgColor
        }
        else if index - myFriendRequestsArray.count - 1 < myFriendsArray.count {
            cell.nameLabel.text = myFriendsArray[index - myFriendRequestsArray.count - 1].userName
            cell.arrowLabel.text = "▶︎"
            let colorIndex = index % colorArray.count
            cell.backgroundColor = colorArray[colorIndex] ?? UIColor.flatBlack()
            cell.layer.borderColor = colorArray[colorIndex]?.cgColor ?? UIColor.flatBlack()?.cgColor
        } else {
            cell.nameLabel.text = ""
            cell.arrowLabel.text = ""
            cell.backgroundColor = Constant.myWhiteColor
            
            cell.layer.borderColor = UIColor(red:0.88, green:0.89, blue:0.90, alpha:1.0).cgColor
        }
        
        
        return cell
    }
    
    let colorArray = [UIColor.flatBlack(), UIColor.flatYellowColorDark(), UIColor.flatTeal(), UIColor.flatRed(), UIColor.flatPlum(), UIColor.flatSkyBlue(), UIColor.flatNavyBlue(), UIColor.flatMint(), UIColor.flatMaroon()]

    
    
    
    
    
    
    // MARK:- UICollectionViewDelegate
    


    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let highlightedColor = cell?.backgroundColor?.withAlphaComponent(0.7) ?? UIColor.flatBlack().withAlphaComponent(0.7)
        cell?.backgroundColor = highlightedColor
        let highlightedBorderColor = cell?.layer.borderColor?.copy(alpha: 0.7) ?? UIColor.flatBlack().withAlphaComponent(0.7).cgColor
        cell?.layer.borderColor = highlightedBorderColor
    }
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let ogColor = cell?.backgroundColor?.withAlphaComponent(1.0) ?? UIColor.flatBlack().withAlphaComponent(1.0)
        cell?.backgroundColor = ogColor
        let ogBorderColor = cell?.layer.borderColor?.copy(alpha: 1.0) ?? UIColor.flatBlack().withAlphaComponent(1.0).cgColor
        cell?.layer.borderColor = ogBorderColor
        
    }
    
    
    
    
    // MARK:- Cell Selected
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let index = returnIndex(row: indexPath.row, section: indexPath.section)
        
        if index == 0 {
            // PERFORM SEGUE TO ADD FRIEND VC
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AddFriendViewController") as! AddFriendViewController
            MIBlurPopup.show(vc, on: self)
        }
        else if index-1 < myFriendRequestsArray.count {
            if let uid = myFriendRequestsArray[index-1].userID {
                presentProfileVC(theUserID: uid)
            }
        }
        else if index - myFriendRequestsArray.count - 1 < myFriendsArray.count {
            if let uid = myFriendsArray[index - myFriendRequestsArray.count - 1].userID {
                presentProfileVC(theUserID: uid)
            }
        } else {
        }
    }
    
    func presentProfileVC(theUserID : String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FriendProfileViewController") as! FriendProfileViewController
        vc.userID = theUserID
        MIBlurPopup.show(vc, on: self)
    }
    
    
    

}






// MARK:- Adjusting size and padding of cells

extension ManageFriendsViewController : UICollectionViewDelegateFlowLayout {
    
    //1
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (CGFloat(itemsPerSection) + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / CGFloat(itemsPerSection)
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if section == 0 {
            var s = sectionInsets
            s.top = 20
            return s
        }
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    

}




protocol FriendManagerProfileUpdated:class {
    func friendProfileUpdated()
}
