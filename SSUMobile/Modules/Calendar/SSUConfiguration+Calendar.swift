//
//  SSUConfiguration+Calendar.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/31/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

extension SSUConfiguration {
    
    private struct Keys {
        static let lastUpdate = "CalendarUpdatedDate"
    }
    
    var calendarLastUpdate: Date? {
        get {
            return date(forKey: Keys.lastUpdate)
        } set {
            set(newValue, forKey: Keys.lastUpdate)
        }
    }
}
