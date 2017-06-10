//
//  SSUAppDelegate.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/7/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import UIKit
import MBProgressHUD
import Mockingjay

@UIApplicationMain
class SSUAppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        SSULogging.setupLogging()
        SSULogging.logDebug("\(SSUDocumentsDirectory())")
        SSULogging.logDebug("\(SSUCachesDirectory())")
        
        setupConfiguration()
        setupStyles()
        
        SSUModuleServices.instance.loadModules()
        
        if !FileManager.default.fileExists(atPath: SSUApplicationSupportDirectory().path) {
            try? FileManager.default.createDirectory(at: SSUApplicationSupportDirectory(), withIntermediateDirectories: true, attributes: nil)
        }
        
        if isFirstLaunchForCurrentVersion() {
            SSULogging.logDebug("First launch")
            clearLocalDatabases()
            SSUModuleServices.instance.setupAll()
            showWelcomeMessage(completion: {
                SSUConfiguration.instance.set(false, forKey: self.firstLaunchKey())
                SSUModuleServices.instance.updateAll()
                self.loadRemoteConfiguration()
            })
        } else {
            SSUModuleServices.instance.setupAll()
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Load settings from moonlight
        if !isFirstLaunchForCurrentVersion() {
            loadRemoteConfiguration()
            SSUModuleServices.instance.updateAll()
        }
    }
    
    func setupStyles() {
        let mainColor = UIColor.ssuBlue
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barTintColor = mainColor
        UINavigationBar.appearance().barStyle = .black
        UIToolbar.appearance().barStyle = .black
        UIToolbar.appearance().barTintColor = mainColor
        UIToolbar.appearance().tintColor = .white
        UISearchBar.appearance().barTintColor = mainColor
        UISearchBar.appearance().tintColor = mainColor
        UISearchBar.appearance().backgroundColor = mainColor
        UISearchBar.appearance().barStyle = .black
        UISegmentedControl.appearance().tintColor = mainColor
        if #available(iOS 9.0, *) {
            UISegmentedControl.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = .white
            UISegmentedControl.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = .white
        }
        
        MBProgressHUD.appearance().contentColor = mainColor
    }
    
    func setupConfiguration() {
        // Defaults not present in the JSON files
        let userDefaults: [String:Any] = [
            SSUDirectorySortOrderKey: kSSUFirstLast.rawValue,
            SSUDirectoryDisplayOrderKey: kSSUFirstLast.rawValue,
            firstLaunchKey(): true
        ]
        SSUConfiguration.instance.registerDefaults(userDefaults)
        SSUConfiguration.instance.registerDefaults(fromFilename: "defaults.json")
    }
    
    func loadRemoteConfiguration() {
        // TODO: move this stuff to SSUConfiguration
        let versionKey = "CFBundleShortVersionString"
        guard let appVersion = Bundle.main.infoDictionary?[versionKey] else {
            SSULogging.logError("Unable to retrieve app version - cannot load remote config")
            return
        }
        let endpoint = "ssumobile/settings/ios/\(appVersion)/"
        guard let baseURL = URL(string: SSUMoonlightBaseURL),
            let configURL = URL(string: endpoint, relativeTo: baseURL) else {
            SSULogging.logError("Unable to create url for remote config")
            return
        }
        if SSUDebugUtils.shouldMockConfig {
            let fileURL = Bundle.main.url(forResource: "defaults.json", withExtension: nil)!
            let data = try! Data(contentsOf: fileURL)
            MockingjayProtocol.addStub(matcher: uri(configURL.absoluteString), builder: jsonData(data))
        }
        SSUConfiguration.instance.loadFrom(url: configURL) { (error) in
            if let error = error {
                SSULogging.logError("Error loading config: \(error)")
            } else {
                SSUModuleServices.instance.loadModules()
            }
        }
    }
    
    func firstLaunchKey() -> String {
        let versionKey = "CFBundleShortVersionString"
        guard let appVersion = Bundle.main.infoDictionary?[versionKey] else {
            SSULogging.logError("Unable to retrieve app version")
            return SSUAppIsFirstLaunchKey
        }
        let key = "\(SSUAppIsFirstLaunchKey)_\(appVersion)"
        return key
    }
    
    func isFirstLaunchForCurrentVersion() -> Bool {
        return SSUConfiguration.instance.bool(forKey: firstLaunchKey())
    }
    
    
    /**
     Remote Control Notification
     
     This is called when the user interacts with the media controls on the lock screen
     or in the command center
     */
    override func remoteControlReceived(with event: UIEvent?) {
        super.remoteControlReceived(with: event)
        guard let receivedEvent = event else {
            return
        }
        if receivedEvent.type == .remoteControl {
            switch (receivedEvent.subtype) {
            case .remoteControlPause,
                 .remoteControlPlay,
                 .remoteControlTogglePlayPause:
                SSURadioStreamer.sharedInstance().togglePlayer()
            default:
                break;
            }
        }
    }
    
    // MARK: - NSUserActivity / CoreSpotlight
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if #available(iOS 9.0, *) {
            if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String, userActivity.activityType == CSSearchableItemActionType {
                let spotlightModules = SSUModuleServices.instance.modulesConformingTo(type: SSUSpotlightSupportedProtocol.self)
                for module in spotlightModules {
                    if module.recognizesIdentifier(identifier) {
                        let viewController = module.viewControllerForSearchableItem(withIdentifier: identifier)
                        NotificationCenter.default.post(name: NSNotification.Name.SSUSpotlightActivityRequestingDisplay, object: viewController)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        if #available(iOS 9.0, *) {
            return userActivityType == CSSearchableItemActionType
        }
        return false
    }
    
    func showWelcomeMessage(completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Welcome to SSUMobile",
                                      message: "Welcome to the lastest version of SSUMobile! In order to provide you with up to date information, some data will be download from internet.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) in
            completion?()
        }))
    }
        
    /**
     Removes any existing Core Data database files stored in the documents directory.
     */
    func clearLocalDatabases() {
        let extensionToDelete = ".sqlite"
        deleteFilesInDirectory(SSUDocumentsDirectory(), matchingExtension: extensionToDelete)
        deleteFilesInDirectory(SSUApplicationSupportDirectory(), matchingExtension: extensionToDelete)
    }
    
    func deleteFilesInDirectory(_ directory: URL?, matchingExtension fileExtension: String) {
        guard let url = directory else { return }
        let exists = FileManager.default.fileExists(atPath: url.path)
        if !exists {
            SSULogging.logError("Directory does not exist: \(url)")
            return
        }
        
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: url.path)
            for path in filePaths {
                if path.hasSuffix(fileExtension) {
                    try FileManager.default.removeItem(atPath: path)
                }
            }
        } catch {
            SSULogging.logError("Unable to find files in directory \(url)")
            return
        }
    }
    
}
