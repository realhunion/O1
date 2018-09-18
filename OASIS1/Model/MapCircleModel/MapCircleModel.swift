//
//  MapCircleModel.swift
//  OASIS1
//
//  Created by Honey on 6/26/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Foundation
import ClassKit
import MapKit

class MapCircleModel : MapTileMonitorDelegate {


    var delegate: MapCircleModelDelegate?

    var tileMonitorDict : [String:MapTileMonitor] = [:]

    let zoomLevel = 17
    let tileCoverage = 4


    init(centerLoc : CLLocationCoordinate2D) {
        centerLocUpdated(centerLoc: centerLoc)
        print("\n MAPCIRCLEMODEL IS init...\n")
    }
    deinit {
        print("\n MAPCIRCLEMODEL IS DE-init...\n")
    }



    func centerLocUpdated (centerLoc : CLLocationCoordinate2D) {

        var newTilesArray : [String] = []
        let centerTileXY = tranformCoordinate(centerLoc.latitude, centerLoc.longitude, withZoom: zoomLevel)
        for x in (centerTileXY.x-(tileCoverage/2)) ... (centerTileXY.x+(tileCoverage/2)) {
            for y in (centerTileXY.y-(tileCoverage/2)) ... (centerTileXY.y+(tileCoverage/2)) {
                let newTile : String = "\(x)-\(y)"
                newTilesArray.append(newTile)
            }
        }

        for (tileID,_) in tileMonitorDict {
            if newTilesArray.contains(tileID) {
                newTilesArray = newTilesArray.filter { $0 != tileID }
            }
            else {

                if let oldTile = tileMonitorDict[tileID] {
                    oldTile.removeListener()
                    // REMOVE MARKERS
                    for circlePoint in oldTile.circleArray {
                        delegate?.mapCircleRemoved(circleID: circlePoint.circleID)
                    }
                    // REMOVE MARKERS
                    tileMonitorDict[tileID] = nil
                    
    
                }
            }
        }

        for (tileID) in newTilesArray {
            let tileMonitor = MapTileMonitor(tileName: tileID)
            tileMonitor.delegate = self
            tileMonitorDict[tileID] = tileMonitor
        }

    }



    // MARK: - DELEGATE Stubs

    func mapCircleCreated(circlePoint: MapCirclePoint) {
        delegate?.mapCircleCreated(circlePoint: circlePoint)
    }

    func mapCircleRemoved(circleID: String) {
        delegate?.mapCircleRemoved(circleID: circleID)
    }




    // MARK: - Utility Functions

    func tranformCoordinate (_ latitude: Double, _ longitude: Double, withZoom zoom: Int) -> (x: Int, y: Int) {
        let tileX = Int(floor((longitude + 180) / 360.0 * pow(2.0, Double(zoom))))
        let tileY = Int(floor((1 - log( tan( latitude * Double.pi / 180.0 ) + 1 / cos( latitude * Double.pi / 180.0 )) / Double.pi ) / 2 * pow(2.0, Double(zoom))))
        return (tileX, tileY)
    }


}

protocol MapCircleModelDelegate {
    func mapCircleCreated(circlePoint: MapCirclePoint)
    func mapCircleRemoved(circleID: String)
}

