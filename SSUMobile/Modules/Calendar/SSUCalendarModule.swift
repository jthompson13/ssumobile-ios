//
//  SSUCalendarModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/31/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

final class SSUCalendarModule: SSUCoreDataModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSUCalendarModule()
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Calendar", comment: "The campus calendar of upcoming events")
    }
    
    var identifier: String {
        return "calendar"
    }
    
    func setup() {
        setupCoreData(modelName: "Calendar", storeName: "Calendar")
    }
    
    func updateData(_ completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Calendar")
        let lastUpdate = SSUConfiguration.instance.calendarLastUpdate
        SSUMoonlightCommunicator.getJSONFromPath("events/event", since: lastUpdate) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while updating \(self.identifier): \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.calendarLastUpdate = Date()
                self.build(json: json) {
                    completion?()
                }
            }
        }
    }
    
    private func build(json: Any, completion: (() -> Void)? = nil) {
        let builder = SSUCalendarBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {
            builder.build(json)
            SSULogging.logDebug("Finish building Calendar")
            completion?()
        }
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "calendar_icon")
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Calendar_iPhone", bundle: nil)
        return storyboard.instantiateInitialViewController()!
    }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
}
