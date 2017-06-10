//
//  SSUConfiguration+About.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/26/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

extension SSUConfiguration {
    
    private struct Keys {
        static let feedbackDate = "LastFeedbackSubmissionDate"
    }
    
    /// The date of the last feedback submission, or Date.distantPast if none
    var lastFeedbackDate: Date {
        get {
            return date(forKey: Keys.feedbackDate) ?? Date.distantPast
        } set {
            set(newValue, forKey: Keys.feedbackDate)
        }
    }
}
