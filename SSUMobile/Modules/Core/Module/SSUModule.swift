//
//  SSUModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/6/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

@objc
protocol SSUModule: NSObjectProtocol {
        
    /** A user-facing title for this module. Should be localized */
    var title: String { get }
    /** A non-user-facing identifier for this module. */
    var identifier: String { get}
    /** Called immediately after application launch to provide modules with a time to set themselves up properly */
    func setup()
    /** Called when the application is updating all modules at once, or manually by view controllers where needed */
    @objc optional func updateData(_ completion: (() -> Void)?)
    ///** Called when the user requests the deletion of all cached data */
    @objc optional func clearCachedData()
}

@objc
protocol SSUModuleUI: SSUModule {
    /** The image that will be used as the button for this module */
    func imageForHomeScreen() -> UIImage?
    /** The module's initial view controller */
    func initialViewController() -> UIViewController
    /**
     Return true if your module is available, or false if the functionality is not available or you do not
     need to present a view controller to the user (ex. just going to open a link in Safari)
     
     If this function is implemented and returns false, no navigation action will take place.
     */
    @objc optional func shouldNavigateToModule() -> Bool

    /** If YES, this module's `viewForHomeScreen` view will be set as the navigation item's rightBarButtonItem */
    @objc optional func showModuleInNavigationBar() -> Bool
    /** 
     The view that shows up on the homescreen and navigates to this module
     
     - note: This is only called if `showModuleInNavigationBar()` returns true
     */
    @objc optional func viewForHomeScreen() -> UIView?
}

class SSUModuleBase: NSObject {
    
    func excludeURLFromBackup(_ urlToExclude: URL?) {
        guard var url = urlToExclude else {
            return
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        
        do {
            try url.setResourceValues(values)
        } catch {
            SSULogging.logError("Error attemping to exclude \(url) from backup: \(error)")
        }
    }
}
