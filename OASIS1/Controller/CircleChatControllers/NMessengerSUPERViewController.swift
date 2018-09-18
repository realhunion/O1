//
//  NMessengerSUPERViewController.swift
//  OASIS1
//
//  Created by Honey on 7/2/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Firebase
import NMessenger
import AsyncDisplayKit
import ChameleonFramework

class NMessengerSUPERViewController: NMessengerViewController, MessageCellProtocol {
    
    var circleID : String!
    var chatID : String!
    
    var usersLiveList : [String:Date] = [:] {
        //FIX: Add UI to ensure you know when you can or can't type.
        didSet {

           var isChattable = false
            
            if let myJoinTime = usersLiveList[Auth.auth().currentUser?.uid ?? "nil"] {
                var myQueueNum = 1
                for (uid, time) in usersLiveList {
                    if time < myJoinTime  && uid != Auth.auth().currentUser?.uid ?? "nil"{
                        myQueueNum += 1
                    }
                }

                if myQueueNum <= Constant.maxUsersInChat {

                    //FIX: more UI stuff + Can type here
                    print("YRN = \(myQueueNum)")
                    isChattable = true
                }
            }
            
            if initialMessageLoadingState == true {
                if isChattable {
                    self.inputBarView.textInputView.isUserInteractionEnabled = true
                }
                else {
                    self.inputBarView.textInputView.isUserInteractionEnabled = false
                }
            }
            
        }
    }
    
    
    
    
    
    var db: Firestore!
    var listener : ListenerRegistration!
    
    var initialMessageLoadingState = false
    var msgAray : [GeneralMessengerCell] = []
    
    private(set) var lastMessageGroup : MessageGroup? = nil
    private(set) var lastMessageGroupUserID : String? = nil
    
    
    
    var colorBubbleAvailableDict : [UIColor:Bool] = [UIColor.flatMint():true,UIColor.flatYellow():true,UIColor.flatWatermelon():true,UIColor.flatPowderBlue():true, UIColor(red:0.54, green:0.77, blue:0.96, alpha:1.0):true]

    var userBubbleColorDict : [String:UIColor] = [:]
    
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        messengerView.scrollToLastMessage(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Firestore Stuff
        db = (UIApplication.shared.delegate as! AppDelegate).db
        
        setUpNMessengerView()
        
        //NMessenger Stuff
        DispatchQueue.main.async(execute: {
            self.messengerView.messengerNode.reloadData()
        })
        
        initializeChatMessagesFromFirebase()
    
    }
    
    deinit {
        print("N.Messenger is DE-INIT\n")
    }
    
    
    
    /////////////////////////////////
    /////////////////////////////////
    /////////////////////////////////
    
    
    func setUpNMessengerView () {
        let maskLayer = CAShapeLayer()
        let maskPath: UIBezierPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: ([.topLeft, .topRight]), cornerRadii: CGSize(width: 10.0, height: 10.0))
        maskLayer.frame = view.bounds
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        
        view.addInnerShadow(onSide: .top, shadowColor: UIColor.black, shadowSize: 3.5, shadowOpacity: 0.5)
        
        messengerView.messengerNode.backgroundColor = UIColor.clear
        messengerView.backgroundColor = UIColor.clear
        view.backgroundColor = UIColor(red:0.94, green:0.95, blue:0.96, alpha:1.0)
        
        sharedBubbleConfiguration = BubbleConfig(incomingColor: UIColor.flatWhite())
        
        self.messengerView.messengerNode.view.isScrollEnabled = false
        
        handleMessengerViewTapPan()
    }
    
    
    /////////////////////////////////
    /////////////////////////////////
    /////////////////////////////////
    
    
    func handleMessengerViewTapPan() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleTapPan(sender:)))
        messengerView.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTapPan(sender:)))
        messengerView.addGestureRecognizer(pan)
    }
    @objc func handleTapPan(sender: UIGestureRecognizer) {
        inputBarView.textInputView.resignFirstResponder()
    }
    
    
    /////////////////////////////////
    /////////////////////////////////
    /////////////////////////////////
    
    func initializeChatMessagesFromFirebase () {
        let docRef = db.collection("Circles").document(circleID).collection("Chats").document(chatID).collection("Messages").limit(to: numMessagesToLoad)
        
        listener = docRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            if self.initialMessageLoadingState == false {
                document.documentChanges.reversed().forEach { diff in
                    if (diff.type == .added) {
                        let data = diff.document.data()
                        let msgBundle : MessageBundle = MessageBundle(data: data)
                        self.addMessageBundleToChat(msgBundle: msgBundle)
                    }
                }
                self.initialMessageLoadingState = true
            }
            else {
                document.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        let data = diff.document.data()
                        let msgBundle : MessageBundle = MessageBundle(data: data)
                        self.addMessageBundleToChat(msgBundle: msgBundle)
                    }
                }
            }
        }
    }
    func removeListener() {
        listener.remove()
    }
    
//    override func getInputBar() -> InputBarView {
//        return NMessengerBarViewV2(controller: self)
    //    }
    
    
    
    /////////////////////////////////
    /////////////////////////////////
    /// Distribution between posting msgBundle to outgoing / incoming
    /////////////////////////////////
    /////////////////////////////////
    
    var numMessagesToLoad : Int = 10
    var numMessagesToLoadCounter : Int = 0
    var firstMessageSent = false
    
    func addMessageBundleToChat(msgBundle : MessageBundle) {
        let myUserID = Auth.auth().currentUser?.uid ?? "nil"
        if(msgBundle.userID == myUserID){
            if(firstMessageSent == false && numMessagesToLoadCounter < numMessagesToLoad) {
                postMessageForOutgoing(msgBundle: msgBundle)
                numMessagesToLoadCounter+=1
            }
        }
        else {
            postMessageForIncoming(msgBundle: msgBundle)
            numMessagesToLoadCounter+=1
        }
        removeExcessMessages()
    }
    
    
    /////////////////////////////////
    /////////////////////////////////
    /// Posting incoming msg into messengerView
    /////////////////////////////////
    /////////////////////////////////
    
    func postMessageForIncoming(msgBundle : MessageBundle) {
        
        var createNewGroup = false
        
        let userName = msgBundle.userName
        let userID = msgBundle.userID
        let userImage = msgBundle.userImage
        
        //Figuring out COLOR SHIT & If new group should be created
        if userID != lastMessageGroupUserID {
            createNewGroup = true
            if userBubbleColorDict[userID] == nil {
                let randomColor = getRandomAvailableBubbleColor()
                sharedBubbleConfiguration = BubbleConfig(incomingColor: randomColor)
                lastMessageGroupUserID = userID
                userBubbleColorDict[userID] = randomColor
            }
            else {
                let userColor = userBubbleColorDict[userID]
                sharedBubbleConfiguration = BubbleConfig(incomingColor: userColor!)
                lastMessageGroupUserID = userID
            }
        }
        
        
        let newMessage = createIncomingMessageNode(msgBundle: msgBundle)
        
        
        if self.lastMessageGroup == nil || self.lastMessageGroup?.isIncomingMessage == false || createNewGroup {
            
            self.lastMessageGroup = self.createMessageGroup()
            
            let avatarImage = decodeBase64Image(imageString: userImage)
            let avatarNode = createImageNode(image: avatarImage)
            self.lastMessageGroup?.avatarNode = avatarNode
            //////////////////////////////////////////////////////////////////////
            //////   ADD AVATAR FROM USERAVATAR PROPERTY /////////////////////////
            //////////////////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////////////////
            
            let footer = ASTextNode()
            let nsAttributes : [NSAttributedStringKey: Any] = [
                .foregroundColor : UIColor(red:0.50, green:0.50, blue:0.50, alpha:1.0),
                .font : UIFont(name: "Helvetica", size: 12.0)
            ]
            footer.attributedText = NSAttributedString(string: userName, attributes: nsAttributes)
            newMessage.footerSpacing = 2.5
            newMessage.footerNode = footer
            
            
            self.lastMessageGroup!.isIncomingMessage = true
            self.messengerView.addMessageToMessageGroup(newMessage, messageGroup: self.lastMessageGroup!, scrollsToLastMessage: false)
            self.messengerView.addMessage(self.lastMessageGroup!, scrollsToMessage: true, withAnimation: .left)
            
        } else {
            
            let lastMessage = lastMessageGroup?.messages.last as! MessageNode
            newMessage.footerSpacing = 2.5
            newMessage.footerNode = lastMessage.footerNode
            lastMessage.footerSpacing = 0.0
            lastMessage.footerNode = nil
            
            self.messengerView.addMessageToMessageGroup(newMessage, messageGroup: self.lastMessageGroup!, scrollsToLastMessage: true)
        }
    }
    
    func createIncomingMessageNode(msgBundle : MessageBundle) -> MessageNode{
        
        // Future FIX.
//        if msgBundle.contentType == "image" {
//
//            print("FIX THIS-------->>------->>------>>>>\n\n")
//            print("FIX THIS-------->>---------->>---->>>>\n\n")
//            print("FIX THIS-------->>------------>>--->>>>\n\n")
//            var theDownloadedImage : UIImage?
//
//            let url = URL(string: msgBundle.userMessage)
//            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
//                //download hit an error so lets return out
//                if let error = error {
//                    print(error)
//                    return
//                }
//
//                DispatchQueue.main.sync(execute: {
//                    if let downloadedImage = UIImage(data: data!) {
//                        theDownloadedImage = downloadedImage
//                    }
//                })
//            }).resume()
//
//            let imageContent = ImageContentNode(image: #imageLiteral(resourceName: "twochainz.png"), bubbleConfiguration: self.sharedBubbleConfiguration)
//            let newMessage = MessageNode(content: imageContent)
//            newMessage.cellPadding = messagePadding
//            newMessage.currentViewController = self
//
//            return newMessage
//
//        }
        
        if msgBundle.contentType == "text" {
            let textContent = TextContentNode(textMessageString: msgBundle.userMessage, currentViewController: self, bubbleConfiguration: sharedBubbleConfiguration)
            let newMessage = MessageNode(content: textContent)
            newMessage.cellPadding = messagePadding
            
            return newMessage
            
        }
        else {
            let textContent = TextContentNode(textMessageString: "Error: Please check your connection.", currentViewController: self, bubbleConfiguration: sharedBubbleConfiguration)
            let newMessage = MessageNode(content: textContent)
            newMessage.cellPadding = messagePadding
            return newMessage
        }
    }
    
    
    
    /////////////////////////////////
    /////////////////////////////////
    /// Posting outgoing msg into messengerView
    /////////////////////////////////
    /////////////////////////////////
    
    func postMessageForOutgoing(msgBundle : MessageBundle) {
        let msgNode = createOutgoingMessageNode(msgBundle: msgBundle)
        postOutgoingMessageNode(theMessageNode: msgNode)
    }
    

    func createOutgoingMessageNode(msgBundle : MessageBundle) -> MessageNode{
        //Future FIX
//        if(msgBundle.contentType == "image") {
//        }
        if(msgBundle.contentType == "text") {
            let textContent = TextContentNode(textMessageString: msgBundle.userMessage, currentViewController: self, bubbleConfiguration: self.sharedBubbleConfiguration)
            let newMessage = MessageNode(content: textContent)
            newMessage.cellPadding = messagePadding
            newMessage.currentViewController = self
            return newMessage
        }
        else{
            let textContent = TextContentNode(textMessageString: "Error. Please Check your connection.", currentViewController: self, bubbleConfiguration: self.sharedBubbleConfiguration)
            let newMessage = MessageNode(content: textContent)
            newMessage.cellPadding = messagePadding
            newMessage.currentViewController = self
            return newMessage
        }
    }
    
    func postOutgoingMessageNode(theMessageNode : MessageNode) {
        if self.lastMessageGroup == nil || self.lastMessageGroup?.isIncomingMessage == true {
            
            self.lastMessageGroup = self.createMessageGroup()
            
            self.lastMessageGroup!.isIncomingMessage = false
            self.messengerView.addMessageToMessageGroup(theMessageNode, messageGroup: self.lastMessageGroup!, scrollsToLastMessage: false)
            self.messengerView.addMessage(self.lastMessageGroup!, scrollsToMessage: true, withAnimation: .right)
            
        } else {
            self.messengerView.addMessageToMessageGroup(theMessageNode, messageGroup: self.lastMessageGroup!, scrollsToLastMessage: true)
        }
    }
    
    
    
    /////////////////////////////////
    /////////////////////////////////
    /// Msgs sent typed from input bar.
    /////////////////////////////////
    /////////////////////////////////
    
    
    override func sendText(_ text: String, isIncomingMessage: Bool) -> GeneralMessengerCell {
        
        let textContent = TextContentNode(textMessageString: text, currentViewController: self, bubbleConfiguration: self.sharedBubbleConfiguration)
        let newMessage = MessageNode(content: textContent)
        newMessage.cellPadding = messagePadding
        newMessage.currentViewController = self
        
        postTextForOutgoing(msgNode: newMessage)
        
        postTextIntoFirebase(theText: text)
        
        removeExcessMessages()
        
        return newMessage
    }
    
    override func sendImage(_ image: UIImage, isIncomingMessage: Bool) -> GeneralMessengerCell {
        let imageContent = ImageContentNode(image: image, bubbleConfiguration: self.sharedBubbleConfiguration)
        let newMessage = MessageNode(content: imageContent)
        newMessage.cellPadding = messagePadding
        newMessage.currentViewController = self
        
        postImageForOutgoing(msgNode: newMessage)
        
        postImageIntoFirebase(theImage: image)
        
        return newMessage
    }
    
    
    func postTextForOutgoing(msgNode : MessageNode) {
        postOutgoingMessageNode(theMessageNode: msgNode)
    }
    func postImageForOutgoing(msgNode : MessageNode) {
        postOutgoingMessageNode(theMessageNode: msgNode)
    }
    
    
    /////////////////////////////////
    /////////////////////////////////
    /// Posting message data to Firebase server
    /////////////////////////////////
    /////////////////////////////////
    
    
    
    func postTextIntoFirebase(theText : String) {
        
        let docTimestamp = generateUniqueTimestamp()
        let data = self.generateMsgDataStrip(contentTypeImageORText: "text", message: theText)
        db.collection("Circles").document(circleID).collection("Chats").document(chatID).collection("Messages").document(docTimestamp).setData(data)
    }
    
    func postImageIntoFirebase(theImage : UIImage) {
//        let imageName = UUID().uuidString
//        let storageRef = Storage.storage().reference().child("Circles").child(circleID).child("Chats").child(chatID).child("\(imageName).jpg")
//
//        if let uploadImage = UIImageJPEGRepresentation(theImage, 0.1) {
//
//            storageRef.putData(uploadImage, metadata: nil, completion: { (metadata, error) in
//
//                if let error = error {
//                    print(error)
//                    return
//                }
//
//                if let imageURL = metadata?.downloadURL()?.absoluteString {
//
//                    let docTimestamp = self.generateUniqueTimestamp()
//                    let data : [String : Any] = self.generateMsgDataStrip(contentTypeImageORText: "image", message: imageURL)
//                    self.db.collection("Circles").document(self.circleID).collection("Chats").document(self.chatID).collection("Messages").document(docTimestamp).setData(data)
//                }
//            })
//        }
    }
    
    //FIX: Add reference to username & reference to userAvatar
    func generateMsgDataStrip(contentTypeImageORText : String, message : String) -> [String:Any] {
        firstMessageSent = true
        
        var image = UIImage(named: "Astroworld1")!
        image = scaleImage(image: image, toSize: CGSize(width: 20, height: 20))!
        let imageString = encodeBase64image(image: image)
        
        
        let data = [
            "contentType": contentTypeImageORText,
            "inOut": "outside",
            "userMessage": message,
            "userID": Auth.auth().currentUser?.uid ?? "nil",
            "userName": "Bobby",
            "userImage": imageString,
            ] as [String : Any]
        return data
    }
    
    
    
    /////////////////////////////////
    /////////////////////////////////
    /// User Avatar Clicked in Chat
    /////////////////////////////////
    /////////////////////////////////
    
    
    func avatarClicked(_ messageCell: GeneralMessengerCell) {
        
        //let theGroup = messageCell as! MessageGroup
        let msgGroup = messageCell as! MessageGroup
        let lastMsg = msgGroup.messages.last as! MessageNode
        let msgNode = lastMsg.contentNode
        let msgBubbleConfig = msgNode?.bubbleConfiguration as! BubbleConfigurationProtocol
        let msgColor = msgBubbleConfig.getIncomingColor()
        
        print("Avatar.........Clicked!!!\n")
        
        var thisUserID : String = ""
        for (uID,colorID) in userBubbleColorDict {
            if colorID == msgColor {
                thisUserID = uID
                break
            }
        }
        
        
        if thisUserID != "" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "FriendProfileViewController") as! FriendProfileViewController
            vc.userID = thisUserID
            MIBlurPopup.show(vc, on: self)
        }
        else {
            print("Couldn't find UserID...")
        }
        
    }
    
    
    
    /////////////////////////
    /////////////////////////
    /// OTHER AMBIGIOUIS~~~
    /////////////////////////
    /////////////////////////
    
    private func createMessageGroup() -> MessageGroup {
        let newMessageGroup = MessageGroup()
        newMessageGroup.delegate = self
        newMessageGroup.messageTable.backgroundColor = UIColor.clear
        newMessageGroup.cellPadding = self.messagePadding
        return newMessageGroup
    }
    
    
    func getRandomAvailableBubbleColor () -> UIColor {
        let colorBubbleAvailableFilteredDict = colorBubbleAvailableDict.filter { (key, value) -> Bool in
            value == true
        }
        let randomIndex = Int(arc4random_uniform(UInt32(colorBubbleAvailableFilteredDict.count)))
        let randomColor = Array(colorBubbleAvailableFilteredDict.keys)[randomIndex]
        self.colorBubbleAvailableDict[randomColor] = false
        return randomColor
    }
    
    class BubbleConfig : StandardBubbleConfiguration {
        var receivingColor : UIColor
        init(incomingColor : UIColor) {
            receivingColor = incomingColor
        }
        override func getIncomingColor() -> UIColor {
            return receivingColor
        }
        override func getOutgoingColor() -> UIColor {
            return UIColor.flatBlack()
        }
    }
    
    func numCharConversion(theString : String) -> String {
        var s = theString
        s = s.replacingOccurrences(of: "0", with: "z")
        s = s.replacingOccurrences(of: "1", with: "y")
        s = s.replacingOccurrences(of: "2", with: "x")
        s = s.replacingOccurrences(of: "3", with: "w")
        s = s.replacingOccurrences(of: "4", with: "v")
        s = s.replacingOccurrences(of: "5", with: "u")
        s = s.replacingOccurrences(of: "6", with: "t")
        s = s.replacingOccurrences(of: "7", with: "s")
        s = s.replacingOccurrences(of: "8", with: "r")
        s = s.replacingOccurrences(of: "9", with: "q")
        return s
    }
    
    func generateUniqueTimestamp() -> String {
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "MMddHHmmssSSS"
        let timestamp = df.string(from: d)
        df.timeStyle = .medium
        let timestamp2 = df.string(from: d)
        let finalTimestamp = numCharConversion(theString: timestamp) + " " + timestamp2
        // -> zxysyxuuzvusw 12:55:04 PM
        return finalTimestamp
    }
    
    func decodeBase64Image(imageString: String) -> UIImage {
        let dataDecoded:NSData = NSData(base64Encoded: imageString, options: NSData.Base64DecodingOptions(rawValue: 0))!
        let decodedimage:UIImage = UIImage(data: dataDecoded as Data)!
        return decodedimage
    }
    
    func encodeBase64image(image : UIImage) -> String {
        let imageData:NSData = UIImagePNGRepresentation(image) as! NSData
        let imageString = imageData.base64EncodedString()
        return imageString
    }
    
    func createImageNode(image : UIImage) -> ASImageNode {
        let avatar = ASImageNode()
        avatar.image = image
        avatar.style.preferredSize = CGSize(width: 20, height: 20)
        avatar.layer.cornerRadius = 10
        return avatar

    }
    
    func scaleImage(image : UIImage, toSize newSize: CGSize) -> UIImage? {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(image.cgImage!, in: newRect)
            let newImage = UIImage(cgImage: context.makeImage()!)
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
    

    ////////////////////////////
    /////////TESTING////////////
    ////////////////////////////
    
    ////////////////////////////
    /////////TESTING////////////
    ////////////////////////////
    
    func removeExcessMessages() {
        let msgCount = self.messengerView.allMessages().count
        print("###\(msgCount)\n")
        if msgCount > 5 {
            let allMsgArray = messengerView.allMessages()
            let deleteMsgArray = Array(allMsgArray.prefix(msgCount-5))
            print("---\(deleteMsgArray.count)\n")
            messengerView.removeMessages(deleteMsgArray, animation: .automatic)
            
        }
    }
    


    
    
}
