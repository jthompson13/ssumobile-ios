//
//  SSUConfiguration+News.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/26/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

extension SSUConfiguration {
    
    private struct Keys {
        static let lastUpdate = "NewsUpdatedDate"
    }
    
    var newsLastUpdate: Date? {
        get {
            return date(forKey: Keys.lastUpdate)
        } set {
            set(newValue, forKey: Keys.lastUpdate)
        }
    }
}
