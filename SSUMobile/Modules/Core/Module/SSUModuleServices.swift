//
//  SSUModuleServices.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/7/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

let SSUModulesEnabledKey = "edu.sonoma.modules.enabled"
let SSUModulesDidLoadNotification = Notification.Name("edu.sonoma.modules.loaded.notification")

/**
 Handles the installation and querying of installed modules.
 
 To use a new module, it must be added to the list of supported modules.
 */
class SSUModuleServices: NSObject {
    
    @objc(sharedInstance)
    static let instance = SSUModuleServices()
    
    override init() {}
    
    var modules: [SSUModule] = []
    var modulesUI: [SSUModuleUI] {
        return modules.flatMap({ $0 as? SSUModuleUI })
    }
    
    /**
     List of all supported modules which may or may not be included based on feature flags
     */
    private var supportedModules: [SSUModule] = {
        var result: [SSUModule] = [
            SSUAboutModule.instance,
            SSUCalendarModule.instance,
            SSUDirectoryModule.instance,
            SSUEmailModule.instance,
            SSUNewsModule.instance,
            SSUMapModule.instance,
            SSUResourcesModule.instance,
            SSURadioModule.instance
        ]
        #if DEBUG
        result.append(SSUDebugModule.instance)
        #endif
        return result
    }()
    
    private var identifiers: [String] {
        var ids = SSUConfiguration.sharedInstance().stringArray(forKey: SSUModulesEnabledKey) ?? []
        #if DEBUG
        ids.append("debug")
        #endif
        return ids
    }
    
    func addModule(_ module: SSUModule) {
        modules.append(module)
    }
    
    func loadModules() {
        modules = []
        for name in identifiers {
            if let module = supportedModules.first(where: { $0.identifier == name }) {
                addModule(module)
            }
        }
        
        NotificationCenter.default.post(name: SSUModulesDidLoadNotification, object: modules)
    }
    
    func modulesConformingTo<T>(type: T.Type) -> [T] {
        return modules.flatMap({ $0 as? T })
    }
    
    @objc
    func modulesConformingToProtocol(_ proto: Protocol) -> [Any] {
        return modules.filter({ $0.conforms(to: proto) })
    }
    
    func getModule(identifier: String) -> SSUModule? {
        return modules.first(where: { $0.identifier == identifier })
    }
    
    func updateAll() {
        modules.forEach({ $0.updateData?(nil) })
    }
    
    func setupAll() {
        modules.forEach({ $0.setup() })
    }
}
