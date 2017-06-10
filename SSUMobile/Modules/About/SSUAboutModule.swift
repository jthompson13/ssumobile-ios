//
//  SSUAboutModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/25/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUAboutModule: SSUModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSUAboutModule()
    
    private let feedbackSubmissionInterval: TimeInterval = 60
    
    /**
     True if the required amount of time between feedback submissions has passed
     */
    var canSubmitFeedback: Bool {
        get {
            let lastSubmission = SSUConfiguration.instance.lastFeedbackDate
            let timeSinceLast = abs(lastSubmission.timeIntervalSinceNow)
            return timeSinceLast >= feedbackSubmissionInterval
        }
    }
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("About", comment: "General information about the app.")
    }
    
    var identifier: String {
        return "about"
    }
    
    func setup() {
        
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return nil
    }
    
    func viewForHomeScreen() -> UIView? {
        let button = UIButton(type: .infoLight)
        return button
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "About", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!
    }

    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return true
    }
}
