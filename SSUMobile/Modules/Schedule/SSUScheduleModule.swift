//
//  SSUScheduleModule.swift
//  SSUMobile
//
//  Created by Eli Simmonds on 4/19/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation


final class SSUScheduleModule: SSUCoreDataModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSUScheduleModule()
    static var jData: [Any] = []
    static var nextAddress = ""
    static var loading = false;
    static var abortDownload = false;
    static let initstr = "https://moonlight.cs.sonoma.edu/api/v1/catalog/course/?term=2177"
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Schedule", comment: "A tool for students to view their classes and search current courses offered at SSU")
    }
    
    var identifier: String {
        return "schedule"
    }
    
    func setup() {
        setupCoreData(modelName: "Schedule", storeName: "Schedule")
    }
    
    
    func updateData(_ completion: (() -> Void)? = nil) {
        if SSUScheduleModule.loading { completion?() }
        SSUScheduleModule.loading = true
        
        SSULogging.logDebug("Updating Catalog")
        
        let keyDate = getDate() ?? NSDate(timeIntervalSince1970: 12)
        let now = NSDate()
        
        if !Calendar.current.isDate(keyDate as Date, inSameDayAs:now as Date) {
            largeDataWarningMessage({
                completion?()
            })
        } else {
            completion?()
        }
 
    }
    
    private func largeDataWarningMessage(_ completion: (() -> Void)? = nil){
        let alert = UIAlertController(title: "Download Warning",
                                      message: "SSU Mobile would like to download the course catalog. Wifi is recommended! Click OK to continue or Cancel to abort",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.updateCatalog {
                completion?()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            completion?()
            
        }))
        
        UIApplication.shared.windows[0].rootViewController?.present(alert, animated: true)
    }
    
    private func getDate() -> NSDate? {
        return SSUCourseBuilder.date()
    }
    
    private func setDate(date: NSDate) {
        SSUCourseBuilder.setDate(date: date)
    }
    
    func updateCatalog(completion: (() -> Void)? = nil) {
        let url = URL(string: SSUScheduleModule.initstr)
        
        SSUCommunicator.getJSONFrom(url!) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Schedule Classes: \(error)")
                completion?()
            } else {
                self.setDate(date: NSDate())
                self.getNext(data: json) {
                    completion?()
                }
            }
        }
    }
    
    func fetchNext(next: String, completion: @escaping (_ result: Any?) -> ()) {
        guard let url = URL(string: next) else {
            return completion(nil)
        }
        
        SSUCommunicator.getJSONFrom(url) { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Schedule Classes: \(error)")
                completion(nil)
            } else {
                completion(json)
            }
        }

    }
    
    
    private func getNext (data: Any?, completion: (() -> Void)? = nil) {
        let builder = SSUCourseBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {

            var retJS: Any?
            (SSUScheduleModule.nextAddress, retJS) = builder.fetchComplete(data ?? 0)
                
            if let js = retJS {
                SSUScheduleModule.jData.append(js)
            }
            
            if SSUScheduleModule.nextAddress != "" {
                self.fetchNext(next: SSUScheduleModule.nextAddress) { (result) in
                    self.getNext(data: result)
                    
                }
            } else {
                self.build(json: SSUScheduleModule.jData as Any ) {
                    completion?()
                }
            }
        }
        
    }

    
    private func build(json: Any, completion: (() -> Void)? = nil) {
        let builder = SSUCourseBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {
            builder.build(json)
            completion?()
        }
    }
    
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "schedule_Icon") 
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Schedule", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()!     }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
    
}



