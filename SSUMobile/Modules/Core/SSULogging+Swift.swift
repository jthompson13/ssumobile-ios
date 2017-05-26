//
//  SSULogging+Swift.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/25/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation
import CocoaLumberjack

/// Provides support for logging in Swift within SSUMobile
class SSULogging: NSObject {
    
    static func setupLogging() {
        DDLog.add(DDASLLogger.sharedInstance, with: ddLogLevel)
        DDLog.add(DDTTYLogger.sharedInstance, with: ddLogLevel)
    }
    
    static func log(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        DDLogDebug(message, level: ddLogLevel, file: file, function: function, line: line)
    }
    
    static func logError(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        DDLogError(message, level: ddLogLevel, file: file, function: function, line: line)
    }
    
    static func logWarn(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        DDLogWarn(message, level: ddLogLevel, file: file, function: function, line: line)
    }
    
    static func logInfo(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        DDLogInfo(message, level: ddLogLevel, file: file, function: function, line: line)
    }
    
    static func logDebug(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        DDLogDebug(message, level: ddLogLevel, file: file, function: function, line: line)
    }
    
    static func logVerbose(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        DDLogVerbose(message, level: ddLogLevel, file: file, function: function, line: line)
    }
}
