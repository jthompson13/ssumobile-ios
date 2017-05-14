//
//  SSUScheduleTableViewContorller.swift
//  SSUMobile
//
//  Created by Jonathon Thompson on 5/6/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUScheduleTableViewController: UITableViewController  {
    
    var context: NSManagedObjectContext = SSUScheduleModule.instance.context!
    var backgroundImageView: UIImageView?
    private var schedule: [SSUSchedule]?
    private var sects: [Sections]? = []
    
    private struct Sections {
        var title: String
        var courses = [SSUCourse]()
        var count = 0
        init(title: String, courses: [SSUCourse]) {
            self.title = title
            self.courses = courses
            self.count = courses.count
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        title = "My Class Schedule"

        if let image = UIImage(named: "table_background_image") {
            backgroundImageView = UIImageView(image: image)
            self.tableView.backgroundView = backgroundImageView
        }
    
        
        let newButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(SSUScheduleTableViewController.goToCatalog))
        self.navigationItem.rightBarButtonItem = newButton
        
        //refresh()
    }
    
    @IBAction func goToCatalog(sender: AnyObject) {
        guard let vc = UIStoryboard(name:"Schedule", bundle:nil).instantiateViewController(withIdentifier: "catalogView") as? SSUCatalogTableViewController else {
                print("Could not instantiate view controller with identifier of type SecondViewController")
                return
            }

        self.navigationController?.pushViewController(vc, animated:true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
        self.tableView.flashScrollIndicators()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
    }
    
    private func refresh() {
        SSUScheduleModule.instance.updateData({
            self.loadSchedule()
        })
    }
    
    private func loadSchedule() {
        let fetchRequest: NSFetchRequest<SSUSchedule> = SSUSchedule.fetchRequest()
        
        do {
            schedule = try context.fetch(fetchRequest)
        } catch {
            SSULogging.logError("Error fetching schedule: \(error)")

        }
        self.getCoursesInSchedule()

        DispatchQueue.main.async {
            self.reloadScheduleTableView()
        }
    }
    
    private func reloadScheduleTableView() {
        tableView.reloadData()
    }

    private func getCoursesInSchedule() {
        var Monday = [SSUCourse]()
        var Tuesday = [SSUCourse]()
        var Wednessday = [SSUCourse]()
        var Thrusday = [SSUCourse]()
        var Friday = [SSUCourse]()
        sects = []
        for course in schedule! {
            if let aCourse = SSUCourseBuilder.course(withID: Int(course.id), inContext: context),
                let days = getDays(aCourse) {
                for day in days {
                    if day == "Monday" {
                        Monday.append(aCourse)
                    }
                    if day == "Tuesday" {
                        Tuesday.append(aCourse)
                    }
                    if day == "Wednesday" {
                        Wednessday.append(aCourse)
                    }
                    if day == "Thursday" {
                        Thrusday.append(aCourse)
                    }
                    if day == "Friday" {
                        Friday.append(aCourse)
                    }
                }
            }
        }
        
        if Monday.count > 0 {
            sects?.append(Sections(title: "Monday", courses: Monday))
        }
        if Tuesday.count > 0 {
            sects?.append(Sections(title: "Tuesday", courses: Tuesday))
        }
        if Wednessday.count > 0 {
            sects?.append(Sections(title: "Wednessday", courses: Wednessday))
        }
        if Thrusday.count > 0 {
            sects?.append(Sections(title: "Thursday", courses: Thrusday))
        }
        if Friday.count > 0 {
            sects?.append(Sections(title: "Friday", courses: Friday))
        }
        
    }
    
    func getDays(_ course: SSUCourse) -> [String]? {
        var days: [String]? = []
        
        if (course.meeting_pattern?.range(of: "M") != nil){
            days!.append("Monday")
        }
        if (course.meeting_pattern?.range(of: "T") != nil){
            days!.append("Tuesday")
        }
        if (course.meeting_pattern?.range(of: "W") != nil){
            days!.append("Wednesday")
        }
        if (course.meeting_pattern?.range(of: "R") != nil){
            days!.append("Thursday")
        }
        if (course.meeting_pattern?.range(of: "F") != nil){
            days!.append("Friday")
        }

        return days
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = sects {
            if( sections.count > 0 ){
                return sections.count
            }
        }
    
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = sects {
            let numberOfSections = sections[section].count
            if( numberOfSections > 0 ){
                return numberOfSections
            }
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete{
            sects?[indexPath.section].courses.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            
            // TODO: Actually delete class
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseViewCell", for: indexPath)
        
        if let theCell = cell as? SSUCourseViewCell{
            theCell.transferClassInfo(course: (sects?[indexPath.section].courses[indexPath.row])!)
            // theCell.layoutMargins = UIEdgeInsets.zero
            // theCell.separatorInset = UIEdgeInsets.zero
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sects?[section].title
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        // header.textLabel?.font = UIFont(name: "Futura", size: 11)
        // header.backgroundColor = UIColorFromHex(rgbValue: 0xf7f7f7)
        header.contentView.backgroundColor = UIColorFromHex(rgbValue: 0x215EA8)
        header.textLabel?.textColor = UIColorFromHex(rgbValue: 0xFFFFFF)
        header.textLabel?.textAlignment = .center
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "courseToDetails"{
            let cell = sender as! SSUCourseViewCell
            if let indexPath = tableView.indexPath(for: cell), let oldClass = sects?[(indexPath.section)].courses[(indexPath.row)] {
                
                print("CSTVC:\tprepare:\tsection = \((indexPath.section))\trow = \((indexPath.row))")

                let detailsVC = segue.destination as! SSUCourseDetailViewController
                detailsVC.passClassData(oldClass)
            }
            
        }
        
//        if segue.identifier == "scheduleToCatalog" {
//            guard let vc = UIStoryboard(name:"Schedule", bundle:nil).instantiateViewController(withIdentifier: "catalogView") as? SSUCatalogTableViewController else {
//                print("Could not instantiate view controller with identifier of type SecondViewController")
//                return
//            }
//            
//            
//            self.navigationController?.pushViewController(vc, animated:true)
////            if let catalog = segue.destination as? SSUCatalogTableViewController {
////                catalog.title = "HI"
////            }
//        }
    }
    
    
}
