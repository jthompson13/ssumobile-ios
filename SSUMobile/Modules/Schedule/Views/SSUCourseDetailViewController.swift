//
//  ViewController.swift
//  tableviewExample
//
//  Created by Sean Cullen on 4/23/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

import UIKit

class SSUCourseDetailViewController: UIViewController {
    var context: NSManagedObjectContext = SSUScheduleModule.instance.context!
    
    @IBOutlet weak var buildingButton: UIButton!
    var classData: SSUCourse?
    var backgroundImageView: UIImageView?
    // var building: SSUBuilding?
    var buildingTapGesture: UITapGestureRecognizer?
    var personTapGesture: UITapGestureRecognizer?
    var enrolled = false
    
    var building: SSUBuilding?
    
    // Outlets to storyboard
    @IBOutlet weak var departmentView: UIView!
    @IBOutlet weak var primaryInfoView: UIView!
    @IBOutlet weak var _description: UILabel!
    @IBOutlet weak var _className: UILabel!
    @IBOutlet weak var _location: UILabel!
    @IBOutlet weak var _building: UILabel!
    @IBOutlet weak var _room: UILabel!
    @IBOutlet weak var _instructor: UILabel!
    @IBOutlet weak var _days: UILabel!
    @IBOutlet weak var _time: UILabel!
    @IBOutlet weak var secondaryInfoView: UIView!
    @IBOutlet weak var _component: UILabel!
    @IBOutlet weak var _units: UILabel!
    @IBOutlet weak var _combinedSection: UILabel!
    @IBOutlet weak var _designation: UILabel!
    @IBOutlet weak var _section: UILabel!
    @IBOutlet weak var _addOrRemove: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = classData?.department

        buildingButton.addTarget(self, action: #selector(handleBuildingClick), for: .touchUpInside)
        roundViewCorners()
        buttonSetup()
        displayClassData()
    }
    
    @IBAction func button(_ sender: Any) {
        if enrolled {
            let fetchRequest: NSFetchRequest<SSUSchedule> = SSUSchedule.fetchRequest()
            let pred = NSPredicate(format: "id = %i", Int((classData?.id)!))
            fetchRequest.predicate = pred
            do{
                let result = try context.fetch(fetchRequest)
                for course in result {
                    context.delete(course)
                }
                try context.save()
            }catch {
                SSULogging.logError("Error deleting course: \(error)")
                return
            }
            
        } else {
            let c = NSEntityDescription.insertNewObject(forEntityName: "SSUSchedule", into: context) as! SSUSchedule
            c.id = (classData?.id)!
            do{
                try context.save()
            }catch {
                SSULogging.logError("Error saving new course: \(error)")
                return
            }
            
            
        }
        
        buttonSetup()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionTriggered(sender: AnyObject) {
        print("hello")
    }
    
    
    
    func handleBuildingClick(/*sender: UITapGestureRecognizer*/){
        performSegue(withIdentifier: "building", sender: self)
    }
    
    
    func handlePersonClick(sender: UITapGestureRecognizer){
        performSegue(withIdentifier: "person", sender: self)
    }
    
    
    func passClassData(_ course: SSUCourse){
        classData = course
    }
    
    func buttonSetup() {
        if isAdd() {
            _addOrRemove.setTitle("ADD", for: .normal)
            _addOrRemove.layer.backgroundColor = UIColorFromHex(rgbValue: 0x428bca).cgColor
            enrolled = false
        } else {
            _addOrRemove.setTitle("DELETE", for: .normal)
            _addOrRemove.layer.backgroundColor = UIColorFromHex(rgbValue: 0xd9534f).cgColor
            enrolled = true
        }
    }
    
    func isAdd() -> Bool {
        let fetchRequest: NSFetchRequest<SSUSchedule> = SSUSchedule.fetchRequest()

        let x = (classData?.id)!
        let n: Int = Int(x)
        let pred: NSPredicate = NSPredicate(format: "id = %i", n)
        
        fetchRequest.predicate = pred
        do {
            let responce = try context.fetch(fetchRequest)
            if((responce.isEmpty)) {
                return true
            } else {
                return false
            }
        } catch {
            SSULogging.logError("Error fetching schedule: \(error)")
        }
        
        return false

    }
    
    
    func displayClassData(){

        _className.text = (classData?.subject ?? "[N/A]") + " " + (classData?.catalog ?? "")!
        
        _description.text = (classData?.descript ?? "")
        
        _instructor.text = "Instructor: " + (classData?.first_name ?? "Staff") + " " + (classData?.last_name ?? "")
        _days.text = getDays(standardMeetingPattern: (classData?.meeting_pattern) ?? "[N/A]")
        _time.text = (classData?.start_time ?? "") + "-" + (classData?.end_time ?? "")
        
        if classData?.component == "ACT"{
            _component.text = "Activity"
        }
        else if classData?.component == "LEC"{
            _component.text = "Lecture"
        }
        else{
            _component.text = "Discussion"
        }
        _units.text = "Units: " + "\((classData?.max_units ?? ""))"
        if ( (classData?.combined_section ?? "") != "" ){
            _combinedSection.text = "Combined Section? Yes"
        }
        else{
            _combinedSection.text = "Combined Section? No"
        }
        _designation.text = "Designation: " + "\((classData?.designation ?? ""))"
        _section.text = "Section " + "\((classData?.section ?? ""))"
        
        if let f_id = classData?.facility_id {
            let add_details = SSUCourseDetailHelper.location(f_id)
            if let building = add_details.building { _building.text = building }
            if let room = add_details.room { _room.text = room }
        }

        
    }
    
    
    func roundViewCorners(){
        departmentView.layer.cornerRadius = 10
        departmentView.layer.borderColor = UIColorFromHex(rgbValue: 0x003268).cgColor // Dark blue
        departmentView.layer.borderWidth = 1
        
        primaryInfoView.layer.cornerRadius = 10
        primaryInfoView.layer.borderColor = UIColorFromHex(rgbValue: 0x003268).cgColor // Dark blue
        primaryInfoView.layer.borderWidth = 1
        
        secondaryInfoView.layer.cornerRadius = 10
        secondaryInfoView.layer.borderColor = UIColorFromHex(rgbValue: 0x003268).cgColor // Dark blue
        secondaryInfoView.layer.borderWidth = 1
    }
    
    
    func getDays(standardMeetingPattern: String) -> String{
        var meetingDays = [String]()
        var days = ""
        if (standardMeetingPattern.range(of: "M") != nil){
            meetingDays.append("Monday")
        }
        if (standardMeetingPattern.range(of: "T") != nil){
            meetingDays.append("Tuesday")
        }
        if (standardMeetingPattern.range(of: "W") != nil){
            meetingDays.append("Wednesday")
        }
        if (standardMeetingPattern.range(of: "R") != nil){
            meetingDays.append("Thursday")
        }
        if (standardMeetingPattern.range(of: "F") != nil){
            meetingDays.append("Friday")
        }
        for day in 0..<meetingDays.count{
            days += meetingDays[day]
            if day < meetingDays.count - 1{
                days += ", "
            }
        }
        return days
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "building"{
            if let f_id = classData?.facility_id {
                let add_details = SSUCourseDetailHelper.location(f_id)
                let Building = add_details.building
            
                building = SSUDirectoryBuilder.building(withName: (Building)!, in: SSUDirectoryModule.instance.context)
                let controller = segue.destination as! SSUBuildingViewController
                controller.loadObject(self.building, in: self.building?.managedObjectContext)
            }
        }
        else{
            print("Unrecognized segue: \(segue)")
        }

    }
    
}
