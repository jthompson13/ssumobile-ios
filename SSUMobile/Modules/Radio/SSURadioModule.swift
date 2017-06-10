//
//  SSURadioModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/8/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation
import UIKit

class SSURadioModule: SSUModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSURadioModule()
    
    @objc
    var radioScheduleURL: URL? {
        if let urlString = SSUConfiguration.instance.string(forKey: SSURadioScheduleURLKey) {
            return URL(string: urlString)
        }
        return nil
    }
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Radio", comment: "The campus online radio status - KSUN Radio")
    }
    
    var identifier: String {
        return "radio"
    }
    
    func setup() {
        
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "radio_icon")
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Radio_iPhone", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!
    }
    
    func shouldNavigateToModule() -> Bool {
        if !SSUConfiguration.instance.bool(forKey: SSURadioStreamEnabledKey) {
            let message = SSUConfiguration.instance.string(forKey: SSURadioStreamDisabledMessageKey)
            let alert = UIAlertController(title: "Radio Unavailable", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
            SSUGlobalNavigationController.sharedInstance().present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
}
