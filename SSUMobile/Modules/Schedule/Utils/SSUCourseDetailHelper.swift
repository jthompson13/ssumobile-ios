//
//  Class.swift
//  SSUMobile
//
//  Created by Sean Cullen on 4/20/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import UIKit

extension String
{
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    // for convenience we should include String return
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(self.startIndex, offsetBy: r.upperBound)
        
        return self[start...end]
    }
}

class SSUCourseDetailHelper {
     struct details {
        var building: String?
        var room: String?
        
        init(_ b: String?, _ r: String?) {
            if let buld = b { building = buld }
            if let rm = r { room = rm }
        }
    }
    
    static func timeConverter(_ time: String?) -> String? {
        guard let time = time else {
            return nil
        }
        
        var hr = 0
        var min = ""
        var twelveHr = ""
        
        if time [0] == "0" {
            hr = Int(time[1..<1])!
        } else {
            hr = Int(time[0..<1])!
        }
        min = time[2..<4]
        
        if hr > 12 {
            hr = hr - 12
            twelveHr = String(hr) + min + " PM"
        } else {
            twelveHr = String(hr) + min + " AM"
        }
        
        return twelveHr
    }
    
    
    static func location(_ facilityID: String? ) -> details {
        var building: String?
        var room: String?
        
        if ((facilityID?.range(of: "IH")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 2)
            building = "International Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "STEV")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Stevenson Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "NICH")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Nichols Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "SALZ")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Salazar Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "DARW")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Darwin Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "GMC")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 3)
            building = "Green Music Center"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "GMC SCHRDH")) != nil){
            // let index = facility?.index((facility?.startIndex)!, offsetBy: 2)
            building = "GMC Schroeder Hall"
            room = ""
        }
        else if ((facilityID?.range(of: "GMC WEILL")) != nil){
            // let index = facility?.index((facility?.startIndex)!, offsetBy: 2)
            building = "GMC: Weill Hall"
            room = ""
        }
        else if ((facilityID?.range(of: "IVES")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Ives Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "CARS")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Carson Hall"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "SHLZ")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Schulz"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "CHALK HILL")) != nil){
            // let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 9)
            building = "Chalk Hill"
            room = "" // (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "PHED")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Physical Education"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "FLDH")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Field House"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "COURTS")) != nil){
            // let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 6)
            building = "Tennis Courts"
            room = "" // (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "ARTS")) != nil){
            let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 4)
            building = "Art Building"
            room = (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "UKIAH")) != nil){
            // let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 5)
            building = "Ukiah"
            room = "" // (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "OFF-SITE")) != nil){
            // let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 8)
            building = "Off-Site"
            room = "" // (facilityID?.substring(from: index!))!
        }
        else if ((facilityID?.range(of: "ONLINE")) != nil){
            // let index = facilityID?.index((facilityID?.startIndex)!, offsetBy: 2)
            building = "Online"
            room = ""// (facilityID?.substring(from: index!))!
        }
        else{
            building = "TBD"
            room = ""
        }
        
        let ret = details(building, room)
        
        return ret
    }
    
}















