//
//  MapCirclePoint.swift
//  OASIS1
//
//  Created by Honey on 6/26/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import MapKit

class MapCirclePoint {
    
    var circleID : String
    var circleLoc : CLLocationCoordinate2D
    
    init(theCircleID : String, theCircleLoc : CLLocationCoordinate2D) {
        circleID = theCircleID
        circleLoc = theCircleLoc
        print("Added circle point:::\n")
    }
    deinit {
        print("CirclePoint marker is deinit.\n")
    }
    
    
}
