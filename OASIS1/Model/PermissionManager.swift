//
//  PermissionClass.swift
//  OASIS1
//
//  Created by Honey on 7/24/18.
//  Copyright © 2018 theDevHoney. All rights reserved.
//

import Sparrow

extension UIViewController : SPRequestPermissionEventsDelegate {

    public func askForAppPermissions() {
        if permissionsLeft() != [] {
            SPRequestPermission.dialog.interactive.present(on: (self), with: permissionsLeft(), dataSource: PermissionDataSource(), delegate: self)
        }
    }
    
    public func permissionsLeft() -> [SPRequestPermissionType] {
        var permissionArray : [SPRequestPermissionType] = []
        
        let isAvailableLocationAlways = SPRequestPermission.isAllowPermission(.locationAlways)
        let isAvailableNotification = SPRequestPermission.isAllowPermission(.notification)
        let isAvailableCamera = SPRequestPermission.isAllowPermission(.camera)
        let isAvailableGallery = SPRequestPermission.isAllowPermission(.photoLibrary)
        
        if !isAvailableLocationAlways {
            permissionArray.append(.locationAlways)
        }
        if !isAvailableNotification {
            permissionArray.append(.notification)
        }
        if !isAvailableCamera {
            permissionArray.append(.camera)
        }
        if !isAvailableGallery {
            permissionArray.append(.photoLibrary)
        }
        
        return permissionArray
    }
    
    
    public func didHide() {
        print("didhide")
        if permissionsLeft() != [] {
            SPRequestPermission.dialog.interactive.present(on: (self), with: permissionsLeft(), dataSource: PermissionDataSource(), delegate: self)
        }
        //FIX: could alter permissiondatasource to change title.
    }
    
    public func didAllowPermission(permission: SPRequestPermissionType) {
        print("allowed")
    }
    
    public func didDeniedPermission(permission: SPRequestPermissionType) {
        print("denied")
    }
    
    public func didSelectedPermission(permission: SPRequestPermissionType) {
        print("selected")
    }
    
}


class PermissionDataSource: SPRequestPermissionDialogInteractiveDataSource {
    
    //override title in dialog view
    override func headerTitle() -> String {
        return "Howdy."
    }
    
    override func headerSubtitle() -> String {
        return "OASIS needs some features to work for you."
    }
}
