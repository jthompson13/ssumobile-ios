//
//  SSUEmailModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/8/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUEmailModule: SSUModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSUEmailModule()
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Email", comment: "Provides access to campus email accounts")
    }
    
    var identifier: String {
        return "email"
    }
    
    func setup() {
        
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "email_icon")
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Email", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!
    }
    
    func shouldNavigateToModule() -> Bool {
        if !SSUConfiguration.instance.bool(forKey: SSUEmailLoginEnabledKey) {
            // The custom login must be broken (ex. something changed on Sonoma's website)
            // so we will show the user the webpage instead
            if let urlString = SSUConfiguration.instance.string(forKey: SSUEmailLDAPURLKey),
                let url = URL(string:urlString) {
                UIApplication.shared.openURL(url)
            }
            return false
        }
        return true
    }
}
