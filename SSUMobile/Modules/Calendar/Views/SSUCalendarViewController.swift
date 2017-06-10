//
//  SSUCalendarViewController.swift
//  SSUMobile
//
//  Created by Eric Amorde on 4/4/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation
import SnapKit

class SSUCalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, UITableViewDataSource, UITableViewDelegate, SSUSelectionDelegate {
    
    private struct Identifiers {
        static let eventCell = "EventCell"
        static let calendarCell = "calendarCell"
        static let eventSegue = "event"
    }
    
    let tableView = UITableView(frame: .zero, style: .plain)
    let calendarView = FSCalendar(frame: .zero)
    let selectEventLabel = UILabel()
    
    var context: NSManagedObjectContext = SSUCalendarModule.instance.context
    
    private var selectedEvent: SSUEvent?
    
    private var unfilteredEvents: [SSUEvent] = []
    private var selectedEvents: [SSUEvent] = []
    private var events: [SSUEvent] {
        if let filter = predicate {
            return unfilteredEvents.filter({ (event) -> Bool in
                filter.evaluate(with: event)
            })
        } else {
            return unfilteredEvents
        }
    }
    
    private var predicate: NSPredicate? {
        didSet {
            calendarView.reloadData()
            reloadEventTableView()
        }
    }
    
    private let tableViewHeaderHeight: CGFloat = 25.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Seawolf Calendar"
        
        applyStyles()
        setupViews()
        
        let filterButton = UIBarButtonItem(title: "Filter", style: .done, target: self, action: #selector(filterButtonPressed(button:)))
        navigationItem.rightBarButtonItem = filterButton
        
        calendarView.select(Date())
        calendarView.reloadData()
        loadEvents()
        reloadEventTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if calendarView.selectedDate == nil {
            calendarView.select(Date())
        }
        
        if let lastUpdate = SSUConfiguration.instance.calendarLastUpdate {
            let interval: TimeInterval = -1 * 60 * 5
            if lastUpdate.timeIntervalSinceNow <= interval {
                refresh()
            }
        } else {
            refresh()
        }
    }
    
    private func setupViews() {
        view.addSubview(calendarView)
        calendarView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(view.frame.height / 2.0)
        }
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.scrollEnabled = true
        calendarView.scrollDirection = .vertical
        calendarView.scope = .month
        calendarView.backgroundColor = UIColor.white
        calendarView.register(SSUCalendarCollectionCell.self, forCellReuseIdentifier: Identifiers.calendarCell)
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 50
        tableView.register(SSUCalendarEventCell.self, forCellReuseIdentifier: Identifiers.eventCell)
        tableView.snp.makeConstraints { (make) in
            make.height.equalTo(0)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        view.addSubview(selectEventLabel)
        view.sendSubview(toBack: selectEventLabel)
        selectEventLabel.snp.makeConstraints { (make) in
            make.top.equalTo(calendarView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        selectEventLabel.textAlignment = .center
        if #available(iOS 9.0, *) {
            selectEventLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        } else {
            selectEventLabel.font = UIFont.boldSystemFont(ofSize: 28.0)
        }
        selectEventLabel.backgroundColor = UIColor.groupTableViewBackground
        selectEventLabel.textColor = UIColor.ssuBlue
        selectEventLabel.text = "No events found"
    }
    
    private func refresh() {
        SSUCalendarModule.instance.updateData({
            self.loadEvents()
        })
    }
    
    private func loadEvents() {
        let fetchRequest: NSFetchRequest<SSUEvent> = SSUEvent.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(SSUEvent.startDate), ascending: true)
        ]
        do {
            unfilteredEvents = try context.fetch(fetchRequest)
        } catch {
            SSULogging.logError("Error fetching events: \(error)")
            unfilteredEvents = []
        }
        
        DispatchQueue.main.async {
            self.reloadEventTableView()
            self.calendarView.reloadData()
        }
    }
    
    private func applyStyles() {
        calendarView.appearance.todayColor = .black
        calendarView.appearance.selectionColor = .ssuBlue
        calendarView.appearance.headerTitleColor = .white
        calendarView.appearance.weekdayTextColor = .white
        
        calendarView.calendarHeaderView.backgroundColor = .ssuBlue
        calendarView.calendarWeekdayView.backgroundColor = .ssuBlue
    }
    
    private func reloadEventTableView() {
        selectedEvents = eventsForDate(calendarView.selectedDate)
        tableView.reloadData()
        tableView.snp.updateConstraints { (make) in
            if selectedEvents.count > 0 {
                make.height.equalTo(view.frame.height - calendarView.frame.height)
            } else {
                make.height.equalToSuperview().multipliedBy(0.0)
            }
        }
    }
    
    private func eventsForDate(_ date: Date?) -> [SSUEvent] {
        guard let date = date else {
            return []
        }
        
        return self.events.filter({ (event) -> Bool in
            if let startDate = event.startDate {
                return Calendar.current.isDate(startDate, inSameDayAs: date)
            }
            return false
        })
    }
    
    // MARK: - FSCalendarDataSource
    
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: Identifiers.calendarCell, for: date, at: position)
        if let calendarCell = cell as? SSUCalendarCollectionCell {
            calendarCell.eventCount = eventsForDate(date).count
            calendarCell.separator = [.top, .bottom, .right, .left]
        }
        return cell
    }
    
    // MARK: - FSCalendarDelegate
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        reloadEventTableView()
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarView.snp.updateConstraints { (make) in
            make.height.equalTo(bounds.height)
        }
        
        reloadEventTableView()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.eventCell, for: indexPath) as? SSUCalendarEventCell else {
            SSULogging.logError("Unable to deqeue correct event cell type")
            return UITableViewCell()
        }
        
        cell.event = selectedEvents[indexPath.row]
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = .ssuBlue
            headerView.tintColor = .white
            headerView.textLabel?.textColor = .white
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableViewHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let selectedDate = calendarView.selectedDate {
            let formattedDate = DateFormatter.localizedString(from: selectedDate, dateStyle: .short, timeStyle: .none)
            return "\(selectedEvents.count) events on \(formattedDate)"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedEvent = selectedEvents[indexPath.row]
        performSegue(withIdentifier: Identifiers.eventSegue, sender: self)
    }
    
    // MARK: - SSUSelectionDelegate
    
    func userDidSelectItem(_ item: Any!, at indexPath: IndexPath!, from controller: SSUSelectionController!) {
        if indexPath.item == 0 && indexPath.section == 0 {
            predicate = nil
        } else if let category = item as? String {
            predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(SSUEvent.category), category])
        }
        navigationController?.popViewController(animated: true)
    }
    
    func selectionControllerDismissed(_ controller: SSUSelectionController!) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Buttons
    
    private func allCategories() -> [String] {
        let request: NSFetchRequest<SSUEvent> = SSUEvent.fetchRequest()
        request.propertiesToFetch = [#keyPath(SSUEvent.category)]
        
        let results = (try? context.fetch(request)) ?? []
        let categories = results.flatMap({ $0.category })
        return Array(Set(categories)).sorted()
    }
    
    func filterButtonPressed(button: UIBarButtonItem) {
        var categories = allCategories()
        categories.insert("All Categories", at: 0)
        
        let controller = SSUSelectionController(items: categories)!
        controller.delegate = self
        
        if predicate != nil, let currentCategory = events.first?.category, let row = categories.index(of: currentCategory) {
            controller.defaultIndex = IndexPath(row: row, section: 0)
        } else {
            controller.defaultIndex = IndexPath(row: 0, section: 0)
        }
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SSUCalendarEventDetailController {
            destination.event = selectedEvent
        }
    }
}
