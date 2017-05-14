//
//  SSUCatalogTableViewController.swift
//  SSUMobile
//
//  Created by Jonathon Thompson on 5/8/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

class SSUCatalogTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate  {
    
    var context: NSManagedObjectContext = SSUScheduleModule.instance.context!
    var backgroundImageView: UIImageView?
    private var catalog: [SSUCourse]?
    private var filterCatalog: [SSUCourse]?
    var searchController: UISearchController!
    var filtering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        title = "SSU Catalog"
        filterCatalog = []
        if let image = UIImage(named: "table_background_image") {
            backgroundImageView = UIImageView(image: image)
            self.tableView.backgroundView = backgroundImageView
        }
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        
        UIBarButtonItem.appearance().tintColor = .white
        
        refresh()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        self.loadCatalog()
    }
    
    private func loadCatalog() {
        let fetchRequest: NSFetchRequest<SSUCourse> = SSUCourse.fetchRequest()
        let sortDescriptor1 = NSSortDescriptor(key: "subject", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "catalog", ascending: true)
        let sortDescriptor3 = NSSortDescriptor(key: "section", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2, sortDescriptor3]
        
        do {
            catalog = try context.fetch(fetchRequest)
        } catch {
            SSULogging.logError("Error fetching schedule: \(error)")
            catalog = []
        }
        
        DispatchQueue.main.async {
            self.reloadScheduleTableView()
        }
    }
    
    private func reloadScheduleTableView() {
        tableView.reloadData()
    }
    
    
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering {
            guard let count = filterCatalog?.count else {
                return 0
            }
            return count
        } else {
            guard let count = catalog?.count else {
                return 0
            }
            return count
        }
        
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseViewCell", for: indexPath)
        if filtering {
            if let theCell = cell as? SSUCourseViewCell{
                theCell.transferClassInfo(course: (filterCatalog![indexPath.row]))
            }
        } else {
            if let theCell = cell as? SSUCourseViewCell{
                theCell.transferClassInfo(course: (catalog![indexPath.row]))
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColorFromHex(rgbValue: 0x215EA8)
        header.textLabel?.textColor = UIColorFromHex(rgbValue: 0xFFFFFF)
        header.textLabel?.textAlignment = .center
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if filtering {
            if segue.identifier == "courseDetailView"{
                let cell = sender as! SSUCourseViewCell
                if let indexPath = tableView.indexPath(for: cell), let aClass = filterCatalog?[(indexPath.row)] {
                    let detailsVC = segue.destination as! SSUCourseDetailViewController
                    detailsVC.passClassData(aClass)
                }
                
            }
        } else {
            if segue.identifier == "courseDetailView"{
                let cell = sender as! SSUCourseViewCell
                if let indexPath = tableView.indexPath(for: cell), let aClass = catalog?[(indexPath.row)] {
                    let detailsVC = segue.destination as! SSUCourseDetailViewController
                    detailsVC.passClassData(aClass)
                }
            }
        }
    }
    
    // MARK: - UISearchResultsUpdater
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        self.searchFor(text: searchString)
        self.tableView.reloadData()
    }
    
    func searchFor(text:String?){
        if (catalog == nil) {
            return
        }
        if (text == ""){
            filterCatalog = catalog
            return
        }
        
        var tempset:Set<SSUCourse>
        var setArray:Array<Set<SSUCourse>> = []
        for searchTerms in (text?.lowercased().components(separatedBy: .whitespaces))!{
            if (searchTerms == ""){
                break
            }
            let innerSet = Set(catalog!.filter({
                (item:SSUCourse) in
                return item.catalog?.lowercased().range(of:searchTerms) != nil ||
                    item.department?.lowercased().range(of:searchTerms) != nil ||
                    item.last_name?.lowercased().range(of:searchTerms) != nil ||
                    item.first_name?.lowercased().range(of:searchTerms) != nil ||
                    item.descript?.lowercased().range(of:searchTerms) != nil
            }))
            
            
            setArray.append(innerSet)
        }
        
        if(setArray.isEmpty) {
            return
        }
        tempset = setArray.removeFirst()
        for s in setArray {
            tempset = tempset.intersection(s)
        }
        
        filterCatalog = Array(tempset)

    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        filtering = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filterCatalog = catalog
        filtering = false
    }

    
    
}
