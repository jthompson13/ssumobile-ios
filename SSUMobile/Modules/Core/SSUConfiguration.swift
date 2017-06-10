//
//  SSUConfiguration.swift
//  SSUMobile
//
//  Created by Eric Amorde on 6/4/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

/**
 Stores basic configuration data on disk, persisting through multiple app launches.
 
 Supports any PLIST (String, Date, Array, Dictionary, Data) as well as some additional types such as URL.
 
 If the type of object you want to store is not supported, you can convert it to a Data object before storing it and then
 convert it from data when accessing it.
 
 The storage is backed by UserDefaults
 
 You can observe changes to individual keys with Key Value Observing
 */
@objc
class SSUConfiguration: NSObject {
    
    enum ConfigurationError: Error {
        case fileNotFound
    }
    
    private let userDefaults: UserDefaults
    
    @objc(sharedInstance)
    static let instance = SSUConfiguration(userDefaults: UserDefaults.standard)
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    var dictionaryRepresentation: [String:Any] {
        return userDefaults.dictionaryRepresentation()
    }
    
    private let _lastLoadDateKey = "edu.sonoma.configuration.last_load"
    
    /**
     The date of the most recent loading of configuration data, either from a file or from a remote URL.
     
     This date does not reflect changes to individual keys
     */
    var lastLoadDate: Date? {
        set {
            set(newValue, forKey: _lastLoadDateKey)
        } get {
            return date(forKey: _lastLoadDateKey)
        }
    }
    
    private func withKVOChange(_ key: String, block: () -> Void) {
        willChangeValue(forKey: key)
        block()
        didChangeValue(forKey: key)
    }
    
    // MARK: Accessors
    
    func object(forKey key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }
    
    func string(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }

    func date(forKey key: String) -> Date? {
        return userDefaults.object(forKey: key) as? Date
    }
    
    func data(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }

    func stringArray(forKey key: String) -> [String]? {
        return userDefaults.stringArray(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }

    func float(forKey key: String) -> Float {
        return userDefaults.float(forKey: key)
    }

    func double(forKey key: String) -> Double {
        return userDefaults.double(forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }

    func url(forKey key: String) -> URL? {
        return userDefaults.url(forKey: key)
    }
    
    // MARK: Setters
    
    func set(_ object: Any?, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(object, forKey: key)
        }
    }
    
    @objc(setString:forKey:)
    func set(_ string: String?, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(string, forKey: key)
        }
    }

    @objc(setDate:forKey:)
    func set(_ date: Date?, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(object, forKey: key)
        }
    }
    
    @objc(setData:forKey:)
    func set(_ data: Data?, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(data as Any?, forKey: key)
        }
    }

    @objc(setStringArray:forKey:)
    func set(_ stringArray: [String]?, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(stringArray, forKey: key)
        }
    }

    @objc(setInteger:forKey:)
    func set(_ integer: Int, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(integer, forKey: key)
        }
    }

    @objc(setFloat:forKey:)
    func set(_ float: Float, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(float, forKey: key)
        }
    }
    
    @objc(setDouble:forKey:)
    func set(_ double: Double, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(double, forKey: key)
        }
    }

    @objc(setBool:forKey:)
    func set(_ bool: Bool, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(bool, forKey: key)
        }
    }

    @objc(setURL:forKey:)
    func set(_ url: URL?, forKey key: String) {
        withKVOChange(key) {
            userDefaults.set(url, forKey: key)
        }
        
    }
    
    /**
     Deletes any existing value for the given key. Functionally the same as setting it to nil
     */
    func removeObject(forKey key: String) {
        withKVOChange(key) { 
            userDefaults.removeObject(forKey: key)
        }
    }
    
    // MARK: Helper
    
    func registerDefaults(_ defaults: [String:Any]) {
        userDefaults.register(defaults: defaults)
    }
    
    func registerDefaults(fromFilename filename: String, completion: (() -> Void)? = nil) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            SSULogging.logError("Unable to retrieve resource url for filename: \(filename)")
            completion?()
            return
        }
        // Don't load this asynchronously because we need it immediately for setting up modules
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            self.registerDefaults(dict)
        } catch {
            SSULogging.logError("Error while attempting to load defaults: \(error)")
            assert(false, "Unable to load defaults")
        }
    }

    func load(dict: [String:Any?]) {
        for (key, value) in dict {
            if value is NSNull {
                removeObject(forKey: key)
            } else {
                set(value, forKey: key)
            }
        }
        lastLoadDate = Date()
    }
    
    
    
    /**
     Loads configuration values from a dictionary provided by the given url.
     
     If the URL is a local file url, the file data will be loaded in the background and parsed as a dictionary.
     If the URL is an HTTP(S) URL, a network request will be performed and the response will be interpreted as JSON.
     */
    func loadFrom(url: URL, completion: ((Error?) -> Void)? = nil) {
        SSUCommunicator.getJSONFrom(url) { (response, obj, error) in
            defer {
                completion?(error)
            }
            if let error = error {
                SSULogging.logError("Error during config JSON loading: \(error)")
            } else if let dict = obj as? [String:Any] {
                self.load(dict: dict)
            } else {
                SSULogging.logError("Received unexpected type when loading configuration: \(type(of: obj))")
            }
        }
    }
    
    /**
     Loads from the given filename in the main bundle
     */
    func loadFrom(filename: String, completion: ((Error?) -> Void)? = nil) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            SSULogging.logError("Unable to find file \(filename)")
            completion?(ConfigurationError.fileNotFound)
            return
        }
        
        loadFrom(url: url, completion: completion)
    }
    
    /**
     Saves current values to disk.
     
     You normally do not need to call this method directly, as configuration is automatically saved periodically.
     - returns: `true` if successfully saved to disc, `false` otherwise
     */
    @discardableResult
    func save() -> Bool {
        return userDefaults.synchronize()
    }
}


/// Deprecated
extension SSUConfiguration {
    @nonobjc
    @available(*, deprecated, renamed: "instance")
    static func sharedInstance() -> SSUConfiguration {
        return instance
    }
    @nonobjc
    @available(*, unavailable, renamed: "set(_:forKey:)")
    func setDate(_ date: Date?, forKey key: String) {}
    @nonobjc
    @available(*, unavailable, renamed: "register(defaults:)")
    func registerDefaults(_ defaults: [String:Any?]) {}
}

