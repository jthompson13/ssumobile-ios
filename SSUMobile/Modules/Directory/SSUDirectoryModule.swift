//
//  SSUDirectoryModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/9/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation
import CoreSpotlight

class SSUDirectoryModule: SSUCoreDataModuleBase, SSUModuleUI, SSUSpotlightSupportedProtocol {
    
    @objc(sharedInstance)
    static let instance = SSUDirectoryModule()
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Directory", comment: "The campus directory containing the contact information of faculty and staff")
    }
    
    var identifier: String {
        return "directory"
    }
    
    func setup() {
        setupCoreData(modelName: "Directory", storeName: "Directory")
    }
    
    func updateData(_ completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Directory")
        updateBuildings {
            self.updateSchools {
                self.updateDepartments {
                    self.updateBuildings {
                        completion?()
                    }
                }
            }
        }
    }
    
    
    func updatePeople(completion: (() -> Void)? = nil) {
        let date = SSUConfiguration.instance.date(forKey:SSUDirectoryPersonUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("directory/person", since:date) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Directory People: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUDirectoryPersonUpdatedDateKey)
                self.buildPeople(json) {
                    completion?()
                }
            }
        }
    }
    
    func updateDepartments(completion: (() -> Void)? = nil) {
        let date = SSUConfiguration.instance.date(forKey:SSUDirectoryDepartmentUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("directory/department", since:date) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Directory departments: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUDirectoryDepartmentUpdatedDateKey)
                self.buildDepartment(json) {
                    completion?()
                }
            }
        }
    }
    
    func updateBuildings(completion: (() -> Void)? = nil) {
        let date = SSUConfiguration.instance.date(forKey:SSUDirectoryBuildingUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("directory/building", since:date) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Directory buildings: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUDirectoryBuildingUpdatedDateKey)
                self.buildBuildings(json) {
                    completion?()
                }
            }
        }
    }

    func updateSchools(completion: (() -> Void)? = nil) {
        let date = SSUConfiguration.instance.date(forKey:SSUDirectorySchoolUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("directory/school", since:date) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Directory schools: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUDirectorySchoolUpdatedDateKey)
                self.buildSchools(json) {
                    completion?()
                }
            }
        }
    }
    
    
    func buildPeople(_ json: Any, completion: (() -> Void)? = nil) {
        guard let data = json as? [Any] else {
            completion?()
            return
        }
        let builder = SSUDirectoryBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.buildPeople(data)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func buildDepartment(_ json: Any, completion: (() -> Void)? = nil) {
        guard let data = json as? [Any] else {
            completion?()
            return
        }
        let builder = SSUDirectoryBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.buildDepartments(data)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func buildSchools(_ json: Any, completion: (() -> Void)? = nil) {
        guard let data = json as? [Any] else {
            completion?()
            return
        }
        let builder = SSUDirectoryBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.buildSchools(data)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func buildBuildings(_ json: Any, completion: (() -> Void)? = nil) {
        guard let data = json as? [Any] else {
            completion?()
            return
        }
        let builder = SSUDirectoryBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.buildBuildings(data)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "directory_icon")
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Directory_iPhone", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!
    }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
    
    // MARK: Spotlight
    
    @available(iOS 9.0, *)
    func searchableIndex(_ index: CSSearchableIndex!, reindexItemWithIdentifier identifier: String!) {
        SSUDirectorySpotlightUtilities.searchableIndex(index, reindexItem: identifier, in: backgroundContext, domain: self.identifier)
    }
    
    @available(iOS 9.0, *)
    func searchAbleIndexRequestingUpdate(_ index: CSSearchableIndex!) {
        SSUDirectorySpotlightUtilities.populateIndex(index, context: backgroundContext, domain: self.identifier)
    }
    
    func recognizesIdentifier(_ identifier: String!) -> Bool {
        return identifier.hasPrefix(self.identifier)
    }
    
    func viewControllerForSearchableItem(withIdentifier identfier: String!) -> UIViewController! {
        let vc = SSUDirectoryViewController.instantiateFromStoryboard()
        vc?.objectToDisplay = SSUDirectorySpotlightUtilities.object(forIdentifier: identifier)
        return vc
    }
}
