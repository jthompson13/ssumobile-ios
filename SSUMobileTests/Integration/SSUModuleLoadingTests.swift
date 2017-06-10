//
//  SSUModuleLoadingTests.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/15/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import XCTest
import Nimble
@testable import SSUMobile

class SSUModuleLoadingTests: XCTestCase {
    
    var services: SSUModuleServices!
    
    override func setUp() {
        super.setUp()
        services = SSUModuleServices()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConfigurationModulesExist() {
        // Ensure that all modules that are specified in the config file actually exist
        let services = self.services!
        services.loadModules()
        
        let moduleNames = SSUConfiguration.instance.stringArray(forKey: SSUModulesEnabledKey)!
        for identifier in moduleNames {
            expect(services.getModule(identifier: identifier)).toNot(beNil())
        }
    }
    
    func testNavBarUIModules() {
        // Ensure that a module which requests to be displayed in the nav bar returns a view to display
        let services = self.services!
        services.loadModules()
        
        for uiModule in services.modulesUI {
            if uiModule.showModuleInNavigationBar?() ?? false {
                expect(uiModule.viewForHomeScreen?()).toNot(beNil())
            }
        }
    }
}
