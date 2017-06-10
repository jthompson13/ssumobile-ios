//
//  SSUResourcesModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/8/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUResourcesModule: SSUCoreDataModuleBase, SSUModuleUI {
        
    @objc(sharedInstance)
    static let instance = SSUResourcesModule()
    
    let articleFetchDateLimit: TimeInterval = 60*60*24*180; // 6 months
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Resources",
                                 comment: "Campus resources, such as phone numbers and web links")
    }
    
    var identifier: String {
        return "resources"
    }
    
    func setup() {
        setupCoreData(modelName: "Resources", storeName: "Resources")
    }
    
    func updateData(_ completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Resources");
        updateSections {
            self.updateResources {
                completion?()
            }
        }
    }
    
    func updateSections(completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Resource Sections");
        let lastUpdate = SSUConfiguration.instance.date(forKey: SSUResourcesSectionsUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("ssumobile/resources/section", since: lastUpdate) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while updating Resources: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUResourcesSectionsUpdatedDateKey)
                self.buildSections(json: json)
                completion?()
            }
        }
        
        SSULogging.logDebug("Finish \(title)")
    }
    
    func updateResources(completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Resource resources");
        let lastUpdate = SSUConfiguration.instance.date(forKey: SSUResourcesResourcesUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("ssumobile/resources/resource", since: lastUpdate) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while updating Resources: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUResourcesResourcesUpdatedDateKey)
                self.buildResources(json: json)
                completion?()
            }
        }
    }
    
    private func buildResources(json: Any) {
        guard let jsonData = json as? [Any] else {
            SSULogging.logError("Incorrect data type returned from resources")
            return
        }
        let builder = SSUResourcesBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {
            builder.buildResources(jsonData)
        }
    }
    
    private func buildSections(json: Any) {
        guard let jsonData = json as? [Any] else {
            SSULogging.logError("Incorrect data type returned from resources sections")
            return
        }
        let builder = SSUResourcesBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {
            builder.buildSections(jsonData)
        }
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "resources_icon")
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Resources", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!
    }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
}
