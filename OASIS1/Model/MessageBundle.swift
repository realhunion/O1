//
//  MessageBundle.swift
//  OASIS1
//
//  Created by Honey on 7/3/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation

class MessageBundle {
    
    var userID : String
    var userName : String
    var userImage : String
    var userMessage : String
    var inOut : String
    var contentType : String
    
    init(data : [String:Any]) {
        
        userID = data["userID"] as! String
        userName = data["userName"] as! String
        userImage = data["userImage"] as! String
        userMessage = data["userMessage"] as! String
        inOut = data["inOut"] as! String
        contentType = data["contentType"] as! String
    }
    
    deinit {
        //print("\n Message Bundle userID:\(userID) _ msg:\(userMessage) is DE-init\n")
    }
    
    
    
}
