//
//  SSUMapModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/9/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUMapModule: SSUCoreDataModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSUMapModule()
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Map", comment: "The campus Map shows the location of campus buildings and provides directions")
    }
    
    var identifier: String {
        return "campusmap"
    }
    
    func setup() {
        setupCoreData(modelName: "Map", storeName: "Map")
    }
    
    func updateData(_ completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Map")
        updatePoints {
            self.updatePerimeters {
                self.updateConnections {
                    completion?()
                }
            }
        }
    }
    
    func updatePoints(completion: (() -> Void)? = nil) {
        let date = SSUConfiguration.instance.date(forKey:SSUMapPointsUpdatedDateKey)
        SSUMoonlightCommunicator.getJSONFromPath("ssumobile/map/point/", since:date) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Map points: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUMapPointsUpdatedDateKey)
                self.buildPoints(json) {
                    completion?()
                }
            }
        }
    }
    
    func updatePerimeters(completion: (() -> Void)? = nil) {
        SSUMoonlightCommunicator.getJSONFromPath("ssumobile/map/perimeter/", since:nil) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Map perimeters: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUMapPerimetersUpdatedDateKey)
                self.buildPerimeters(json) {
                    completion?()
                }
            }
        }
    }
    
    func updateConnections(completion: (() -> Void)? = nil) {
        SSUMoonlightCommunicator.getJSONFromPath("ssumobile/map/point_connection/", since:nil) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Map connections: \(error)")
                completion?()
            } else {
                SSUConfiguration.instance.set(Date(), forKey: SSUMapPerimetersUpdatedDateKey)
                self.buildConnections(json) {
                    completion?()
                }
            }
        }
    }

    
    func buildPoints(_ json: Any, completion: (() -> Void)? = nil) {
        let builder = SSUPointsBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.build(json)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func buildPerimeters(_ json: Any, completion: (() -> Void)? = nil) {
        let builder = SSUBuildingPerimetersBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.build(json)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func buildConnections(_ json: Any, completion: (() -> Void)? = nil) {
        let builder = SSUConnectionsBuilder()
        builder.context = backgroundContext
        builder.context.perform {
            builder.build(json)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "map_icon")
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Map_iPhone", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!
    }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
}
