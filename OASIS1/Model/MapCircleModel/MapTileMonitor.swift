//
//  MapTileModel.swift
//  OASIS1
//
//  Created by Honey on 6/26/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import MapKit
import Firebase

class MapTileMonitor {
    
    var delegate: MapTileMonitorDelegate?
    
    var listener : ListenerRegistration!
    
    var db : Firestore!
    var circleArray : [MapCirclePoint] = []
    
    var tileTitle : String!
    
    init(tileName : String) {
        db = (UIApplication.shared.delegate as! AppDelegate).db
        tileTitle = tileName
        monitorTile(tileName: tileName)
    }
    deinit {
        //print("Map Tile Monitor is de-init.")
    }

    
    
    func monitorTile (tileName : String) {
        listener = db.collection("Grid").document("Circles").collection(tileName).addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching resource\n: \(error!)")
                return
            }
            
            document.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    if let lat = diff.document.data()["latitude"] as? CLLocationDegrees, let long = diff.document.data()["longitude"] as? CLLocationDegrees {
                        
                        let circlePoint = MapCirclePoint(theCircleID: diff.document.documentID, theCircleLoc: CLLocationCoordinate2D(latitude: lat, longitude: long))

                        self.circleArray.append(circlePoint)
                        self.delegate?.mapCircleCreated(circlePoint: circlePoint)
                        

                    }
                }
                if (diff.type == .removed) {

                    self.circleArray = self.circleArray.filter { $0.circleID != diff.document.documentID }
                    self.delegate?.mapCircleRemoved(circleID: diff.document.documentID)
                    

                }
            }
        }
    }
    
    func removeListener() {
        listener.remove()
    }
    
    
}


protocol MapTileMonitorDelegate {
    func mapCircleCreated(circlePoint: MapCirclePoint)
    func mapCircleRemoved(circleID: String)
}
