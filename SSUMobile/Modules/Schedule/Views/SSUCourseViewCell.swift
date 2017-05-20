//
//  SSUCourseViewCell.swift
//  SSUMobile
//
//  Created by Sean Cullen on 5/6/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

import UIKit

class SSUCourseViewCell: UITableViewCell {
    var course: SSUCourse?
    
    @IBOutlet weak var ClassName: UILabel!
    @IBOutlet weak var TimeFrame: UILabel!
    @IBOutlet weak var Professor: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        print("CourseViewCell")
        self.layer.cornerRadius = 10
        self.layer.borderColor = UIColorFromHex(rgbValue: 0x003268).cgColor // Dark blue
        self.layer.borderWidth = 1
        self.layer.backgroundColor = UIColorFromHex(rgbValue: 0xFFFFFF).withAlphaComponent(0.6).cgColor
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func transferClassInfo(course: SSUCourse) {
        self.course = course
        stringForCell()
    }
    
    
    func stringForCell(){
        let instructor = "\(course?.first_name ?? "Staff") \(course?.last_name ?? "")"
        ClassName.text = "\(course?.subject ?? "[N/A]") \(course?.catalog ?? "[N/A]") - \(course?.component ?? "[N/A]")"
        TimeFrame.text = "\(course?.start_time ?? "[N/A]") - \(course?.end_time ?? "[M/A]")"
        Professor.text = instructor
    }
    
    
}
