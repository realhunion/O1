//
//  ViewController.swift
//  OASIS1
//
//  Created by Honey on 6/26/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import UIKit
import Mapbox
import Firebase
import CoreLocation
import ChameleonFramework
import AsyncDisplayKit
import Sparrow

class MapViewController: DeckPresentationViewController, CLLocationManagerDelegate, MGLMapViewDelegate, MapCircleModelDelegate {
    
    
    
    
    @IBOutlet weak var circleButton: UIButton!
    
    @IBOutlet weak var triangleButton: UIButton!
    
    
    var db : Firestore!
    var mapView : MGLMapView!
    var CircleModel : MapCircleModel!
    
    var markerDict : [String:MGLAnnotation] = [:]
    
    let locationManager = CLLocationManager()
    
    
    

    override func viewDidAppear(_ animated: Bool) {
        askForAppPermissions()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        db = (UIApplication.shared.delegate as! AppDelegate).db
        
        
        initLocationServices()
        let vv = UIView()
        vv.backgroundColor = UIColor.black
        self.view.addSubview(vv)
        initMapView()
        
        CircleModel = MapCircleModel(centerLoc: mapView.centerCoordinate)
        CircleModel.delegate = self
        
        view.addSubview(circleButton)
        view.addSubview(triangleButton)
        
        handleTap()
        
        print("Map View Controller is init.")
        
    }
    
    deinit {
        print("Map View Controller is de-init.")
    }
    
    func deInitNecessities() {
        self.transitioningDelegate = nil
        self.CircleModel.delegate = nil
        for (_,tileMonitor) in self.CircleModel.tileMonitorDict {
            tileMonitor.removeListener()
            tileMonitor.circleArray = []
            tileMonitor.delegate = nil
        }
        locationManager.delegate = nil
        mapView.delegate = nil
        
    }
    
    
    
    
    
    
    
    // Triangle Button Tap Response
    
    @IBAction func triangleButtonTapped(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "HomeShellViewController") as! HomeShellViewController
        
        vc.modalPresentationStyle = .custom
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        vc.transitioningDelegate = self
        vc.delegate = self
        //FIX: THIS THE PROBLEM.
        
        circleButtonStatus.status = .neutral
        
        self.present(vc, animated: true, completion: nil)
        
        
    }
    
    
    
    func dismissRulesCircleChatVC() {
        if let circleChatVC = self.presentedViewController as? CircleChatViewController {
            circleChatVC.deInitNecessities()
            updateCircleButtonStatusFromMyLocation()
            presentationAnimator?.dismissalTransitionWillBegin()
        }
    }
    
    func dismissRulesHomeVC() {
        if let homeShellVC = self.presentedViewController as? HomeShellViewController {
            presentationAnimator?.dismissalTransitionWillBegin()
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        
        print("ppp dimiss")
        
    
        dismissRulesCircleChatVC()
        dismissRulesHomeVC()
        
        super.dismiss(animated: flag, completion: completion)
        
        self.presentationAnimator = nil
    }
    
    
    
    
    
    
    // Map Circle Model Delegate Protocol & location conveying function
    
    func mapCircleCreated(circlePoint: MapCirclePoint) {
        let marker = MGLPointAnnotation()
        marker.coordinate = circlePoint.circleLoc
        marker.title = circlePoint.circleID
        mapView.addAnnotation(marker)
        markerDict[circlePoint.circleID] = marker
        
        let x = circleButtonStatus.status
        if x == .creation || x == .join {
            //updateCircleButtonStatusFromMyLocation()
            print("update\n")
        }
    }
    
    func mapCircleRemoved(circleID: String) {
        
        if let marker = markerDict[circleID] {
            mapView.removeAnnotation(marker)
            markerDict[circleID] = nil
        }
        
        let x = circleButtonStatus.status
        if x == .creation || x == .join {
            //updateCircleButtonStatusFromMyLocation()
            print("update\n")
        }
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        
        CircleModel?.centerLocUpdated(centerLoc: mapView.centerCoordinate)
        
        print("did change...")
    }
    
    
    
    
    
    
    
    
    
    /// Tap on map as circle button press
    
    func handleTap() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
    }
    @objc @IBAction func handleMapTap(sender: UITapGestureRecognizer) {
        guard let myLoc = self.locationManager.location else { return }
        
        let camera = MGLMapCamera(lookingAtCenter: myLoc.coordinate, fromDistance: 1000, pitch: 45, heading: 360)
        self.mapView.fly(to: camera, withDuration: -1, completionHandler: nil)
        self.updateCircleButtonStatusFromMyLocation()
        self.CircleModel?.centerLocUpdated(centerLoc: myLoc.coordinate)
    }
    
    func tranformCoordinate (_ latitude: Double, _ longitude: Double, withZoom zoom: Int) -> (x: Int, y: Int) {
        let tileX = Int(floor((longitude + 180) / 360.0 * pow(2.0, Double(zoom))))
        let tileY = Int(floor((1 - log( tan( latitude * Double.pi / 180.0 ) + 1 / cos( latitude * Double.pi / 180.0 )) / Double.pi ) / 2 * pow(2.0, Double(zoom))))
        return (tileX, tileY)
    }
    
    
    
    
    
    
    
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if let circleID = annotation.title {
            if let cID = circleID {
                presentCircle(circleID: cID)
            }
        }
        
        print("anno pressed.\n")
    }

    
    func presentCircle(circleID : String) {
        //Present circle code
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CircleChatViewController") as! CircleChatViewController
        vc.circleID = circleID
        
        vc.transitioningDelegate = self
        vc.delegate = self
        vc.modalPresentationStyle = .custom
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        self.present(vc, animated: true) {
            guard let myLoc = self.locationManager.location else { return }
            
            let camera = MGLMapCamera(lookingAtCenter: myLoc.coordinate, fromDistance: 1000, pitch: 45, heading: 360)
            self.mapView.fly(to: camera, withDuration: -1, completionHandler: nil)
        }
        
        
    }
    
    

    
    
    
    
    
    /////////////////////////
    /////////////////////////
    /// Server-Side Circle Creation & Circle Check
    /////////////////////////
    /////////////////////////
    
    // Checks if circleCreationValid. Completion handler returns true + nil if so. false + circleID of circle in vicinity. Improve to make this check server not updated list.
    // FIX : If markers not in view already. they get skipped. ex. intiial button tap.
    func isCircleCreationValid(myLocation : CLLocation, finished: @escaping (_ isValid : Bool, _ circleID : String) -> Void){
        
        let tile = tranformCoordinate(myLocation.coordinate.latitude, myLocation.coordinate.longitude, withZoom: 18)
        let tileString : String = "\(tile.x)-\(tile.y)"
        let gridRef = db.collection("Grid").document("Circles").collection("\(tileString)")
        gridRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error of circleCreationValid: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if let lat = document.data()["latitude"] as? CLLocationDegrees, let long = document.data()["longitude"] as? CLLocationDegrees {
                        let loc = CLLocation(latitude: lat, longitude: long)
                        if loc.distance(from: myLocation) < 5 {
                            print(loc.distance(from: myLocation))
                            let circleID = document.documentID
                            finished(false, circleID)
                            return
                        }
                    }
                }
                //FIX: Gets called even if querySnapshot http connection error.
                finished(true, "nil")
                return
                
            }
        }
    }
    
    func createCircle(myLocation : CLLocation) -> String {
        
        let circleRef = db.collection("Circles").document()
        let circleID = circleRef.documentID
        let circleData = [
            "creatorUID" : Auth.auth().currentUser?.uid ?? "nil",
            "latitude": myLocation.coordinate.latitude,
            "longitude": myLocation.coordinate.longitude,
            "timeCreated": FieldValue.serverTimestamp()
            ] as [String : Any]
        circleRef.setData(circleData)
        
        let chatRef = db.collection("Circles").document("\(circleID)").collection("Chats").document("aaaaaaaaaaaaaaa")
        let chatData = [
            "usersLiveList": [:]
        ] as [String : [String:Any]]
        chatRef.setData(chatData)
        
        
        let msgRef = db.collection("Circles").document("\(circleID)").collection("Chats").document("aaaaaaaaaaaaaaa").collection("Messages").document("zzzzzzzzzzzzzzz")
        let msgData = [
            "contentType": "text",
            "inOut": "outside",
            "userMessage": "Circle Initiated. Inviting Users...",
            "userID": "Cyrus",
            "userName": "Cyrus",
            "userImage": Constant.cyrusAvatarString,
        ] as [String : Any]
        msgRef.setData(msgData)
        
        let tile = tranformCoordinate(myLocation.coordinate.latitude, myLocation.coordinate.longitude, withZoom: 17)
        let tileString : String = "\(tile.x)-\(tile.y)"
        let gridRef = db.collection("Grid").document("Circles").collection("\(tileString)").document("\(circleID)")
        let gridData = [
            "latitude": myLocation.coordinate.latitude,
            "longitude": myLocation.coordinate.longitude
            ] as [String : Any]
        gridRef.setData(gridData)
        
        return circleID
    }
    
    
    
    
    
    
    /////////////////////////
    /////////////////////////
    /// Circle Button Tapped Actions
    /////////////////////////
    /////////////////////////
    struct CircleButtonStatus {
        var status : ButtonStatus
        var nearbyCircleID : String?
    }
    enum ButtonStatus {
        case creation
        case join
        case neutral
    }
    // creation if can create at userLoc, join if circle near userLoc, neutral if anywhere/thing else.
    var circleButtonStatus : CircleButtonStatus = CircleButtonStatus(status: .neutral, nearbyCircleID: nil) {
        didSet {
            let x = circleButtonStatus.status
            if x == .creation {
                circleButton.setTitleColor(UIColor.flatSkyBlue(), for: .normal)
                circleButtonStatus.nearbyCircleID = nil
            }
            if x == .join {
                circleButton.setTitleColor(UIColor.flatGreen(), for: .normal)
            }
            if x == .neutral {
                circleButton.setTitleColor(UIColor(red:0.92, green:0.92, blue:0.92, alpha:1.0), for: .normal)
                circleButtonStatus.nearbyCircleID = nil
            }
        }
    }
    
    @IBAction func circleButtonTapped(_ sender: UIButton) {
        
        guard let myLoc = locationManager.location else { return }
        
        let x = circleButtonStatus.status
        if x == .creation {
            let circleID = createCircle(myLocation: myLoc)
            presentCircle(circleID: circleID)
            // could be completition handler; create then, present right after.
        }
        if x == .join {
            if let circleID = circleButtonStatus.nearbyCircleID {
                presentCircle(circleID: circleID)
            }
        }
        if x == .neutral {
            let camera = MGLMapCamera(lookingAtCenter: myLoc.coordinate, fromDistance: 1000, pitch: 45, heading: 360)
            
            mapView.fly(to: camera, withDuration: -1, completionHandler: nil)
            self.updateCircleButtonStatusFromMyLocation()
            self.CircleModel?.centerLocUpdated(centerLoc: myLoc.coordinate)
        }
        
    }
    
    
    
    
    var continueCircleButtonUpdate = true
    
    //Based off userLoc, update the circleButtonColor and respective circleButtonStatus.
    func updateCircleButtonStatusFromMyLocation() {
        guard let loc = locationManager.location else { return }
        
        continueCircleButtonUpdate = true
        
        isCircleCreationValid(myLocation: loc) { (isValid, circleID) in
            if self.continueCircleButtonUpdate == true {
                
                print("isValid: \(isValid)")
                
                if isValid == true {
                    self.circleButtonStatus.status = .creation
                }
                if isValid == false {
                    self.circleButtonStatus.status = .join
                    self.circleButtonStatus.nearbyCircleID = circleID
                }
            }
        }
    }
    
    
    
    
    
    func mapView(_ mapView: MGLMapView, regionWillChangeWith reason: MGLCameraChangeReason, animated: Bool) {
        //If hand movement, convert to gray button, and neutral state.

        if reason != .programmatic {
            let x = circleButtonStatus.status
            if x == .creation || x == .join {
                circleButtonStatus.status = .neutral
            }
            continueCircleButtonUpdate = false

        }
        
    }
    
    
    
    
    
    
    
    
    func initMapView() {
        guard let myLoc = locationManager.location else { return }
        
        let myMapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL)
        mapView = myMapView
        
        myMapView.delegate = self
        myMapView.logoView.isHidden = true
        myMapView.attributionButton.isHidden = true
        mapView.showsUserLocation = true
        //FIX: Only start this command when approved for location services. else it prompts.
        
        myMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myMapView.setCenter(myLoc.coordinate, zoomLevel: 17, animated: false)
        self.view = myMapView
        
    }
    
    func initLocationServices() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        //locationManager.showsBackgroundLocationIndicator = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.distanceFilter = 10

    }
    
    
    
    
    
    // MARK:- My Location Changed Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let lastLoc = locations.last else { return }
        
        //Follow userLoc if centered.
        let x = circleButtonStatus.status
        if x == .creation || x == .join {
            let camera = MGLMapCamera(lookingAtCenter: lastLoc.coordinate, fromDistance: 1000, pitch: 45, heading: 360)
            mapView.fly(to: camera, withDuration: -1, completionHandler: nil)
            self.updateCircleButtonStatusFromMyLocation()
        }
        
        //Update Firebase with loco
        
        updateFirebaseMyLocation(location: lastLoc)
    }
    
    
    let date = Date()
    let calendar = Calendar.current
    
    func updateFirebaseMyLocation(location : CLLocation) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        //print("update firebase \(generateUniqueTimestamp())- \(location.altitude), \(location.coordinate.latitude)")
        
        //Update Firebase with my location
        let userBaseData = ["latitude":location.coordinate.latitude, "longitude":location.coordinate.longitude, "altitude":location.altitude]
        //self.db.collection("User-Base").document(uid).setData(userBaseData, merge: true)
        
        
    }
    
    func generateUniqueTimestamp() -> String {
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "MMddHHmmssSSS"
        let timestamp = df.string(from: d)
        df.timeStyle = .medium
        let timestamp2 = df.string(from: d)
        // -> zxysyxuuzvusw 12:55:04 PM
        return timestamp2
    }
    
    
    
}

extension MapViewController {
    
    
    
    //// TESTING//// TESTING
    //// TESTING
    //// TESTING
    //// TESTING
    //// TESTING
    
    func mapView(_ mapView: MGLMapView, regionDidChangeWith reason: MGLCameraChangeReason, animated: Bool) {
        print("ssss did change")
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        print("sss: \(mapView.centerCoordinate)")
    }
    
    

    
}

