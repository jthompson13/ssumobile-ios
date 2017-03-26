//
//  SSUAboutModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/25/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUAboutModule: SSUModuleBase, SSUModuleUI {
    
    static let instance = SSUAboutModule()
    
    private struct Settings {
        static let lastFeedbackDate = "LastFeedbackSubmissionDate"
    }
    
    private let feedbackSubmissionInterval: TimeInterval = 60
    
    var lastFeedbackDate: Date {
        get {
            return SSUConfiguration.sharedInstance().date(forKey: Settings.lastFeedbackDate)
        } set {
            SSUConfiguration.sharedInstance().setDate(newValue, forKey: Settings.lastFeedbackDate)
        }
    }
    
    /**
     True if the required amount of time between feedback submissions has passed
     */
    var canSubmitFeedback: Bool {
        get {
            let lastSubmission = lastFeedbackDate
            let timeSinceLast = abs(lastSubmission.timeIntervalSinceNow)
            return timeSinceLast >= feedbackSubmissionInterval
        }
    }
    
    // MARK: SSUModule
    
    override static func sharedInstance() -> SSUAboutModule {
        return instance
    }
    
    func title() -> String {
        return NSLocalizedString("About", comment: "General information about the app.")
    }
    
    func identifier() -> String {
        return "about"
    }
    
    override func setup() {
        super.setup()
        SSUConfiguration.sharedInstance().registerDefaults([
            Settings.lastFeedbackDate: Date.distantPast
        ])
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