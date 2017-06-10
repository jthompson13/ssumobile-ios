//
//  SSUNewsViewController.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/26/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation
import SafariServices

class SSUNewsViewController: SSUCoreDataTableViewController, SSUSelectionDelegate {
    
    private let cellIdentifier: String = "SSUArticle"
    
    private let autoUpdateDelay: TimeInterval = 60 * 5
    
    var predicate: NSPredicate? {
        didSet {
            fetchedResultsController?.fetchRequest.predicate = predicate
            performFetch()
            tableView.reloadData()
        }
    }
    
    var filterButton: UIBarButtonItem!
    var context: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "University News"
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        
        context = SSUNewsModule.instance.context
        fetchedResultsController = self.makeFetchedResultsController()
        searchFetchedResultsController = self.makeFetchedResultsController()
        searchKey = "title"
        
        filterButton = UIBarButtonItem(title: "Filter", style: .done, target: self, action: #selector(self.filterButtonPressed))
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flexibleButton, filterButton, flexibleButton]
        
        tableView.register(SSUNewsArticleTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.estimatedRowHeight = round(UIScreen.main.bounds.height / 4.0)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = false
        if let lastUpdate = SSUConfiguration.instance.newsLastUpdate {
            if abs(lastUpdate.timeIntervalSinceNow) > autoUpdateDelay {
                refresh()
            }
        } else {
            refresh()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: UITableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SSUNewsArticleTableViewCell else {
            SSULogging.logError("Unable to dequeue news article cell")
            return UITableViewCell()
        }
        
        cell.article = self.object(atIndex: indexPath) as? SSUArticle
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let article = object(atIndex: indexPath) as? SSUArticle,
            let link = article.link,
            let articleURL = URL(string: link) else {
            SSULogging.logError("Unable to retrieve article of selected row or article is missing link")
            return
        }
        
        if #available(iOS 9.0, *) {
            let vc = SFSafariViewController(url: articleURL, entersReaderIfAvailable: true)
            if #available(iOS 10.0, *) {
                vc.preferredBarTintColor = .ssuBlue
            }
            present(vc, animated: true, completion: nil)
        } else {
            let vc = SSUWebViewController()
            vc.urlToLoad = articleURL
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    // MARK: Actions
    
    @objc
    func refresh() {
        SSULogging.logDebug("Refresh News")
        if !(refreshControl?.isRefreshing ?? false) {
            refreshControl?.beginRefreshing()
        }
        SSUNewsModule.instance.updateData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.refreshControl?.endRefreshing()
            }
            self.tableView.reloadData()
        }
    }
    
    @objc
    func filterButtonPressed() {
        var categories: [String] = ["All Categories"]
        categories.append(contentsOf: allCategories())
        
        let selectionVc = SSUSelectionController(items: categories)!
        selectionVc.delegate = self
    }
    
    // MARK: SSUSelectionDelegate
    
    func userDidSelectItem(_ item: Any!, at indexPath: IndexPath!, from controller: SSUSelectionController!) {
        let category = item as! String
        if category == "All Categories" {
            predicate = nil
            filterButton.title = "Filter"
        } else {
            filterButton.title = category
            predicate = NSPredicate(format: "category = %@", category)
        }
        
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func selectionControllerDismissed(_ controller: SSUSelectionController!) {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: Search
    
    override func searchPredicate(forText searchText: String) -> NSPredicate {
        let base = basePredicate()
        let search = super.searchPredicate(forText: searchText)
        if let existingPredicate = self.predicate {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [base, search, existingPredicate])
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [base, search])
        }
    }
    
    // MARK: NSFetchedResultsController
    
    private func basePredicate() -> NSPredicate {
        let fetchCutoff = Date(timeIntervalSinceNow: -1*abs(SSUNewsModule.instance.articleFetchDateLimit))
        return NSPredicate(format: "published >= %@", argumentArray: [fetchCutoff])
    }
    
    func makeFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest: NSFetchRequest<SSUArticle> = SSUArticle.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "published", ascending: false)
        ]
        fetchRequest.predicate = basePredicate()
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: "published",
                                                    cacheName: nil)
        return controller as! NSFetchedResultsController<NSFetchRequestResult>
    }
    
    // MARK: Helper
    
    private func allCategories() -> [String] {
        let request = NSFetchRequest<NSDictionary>(entityName: "SSUArticle")
        let keyName = "category"
        request.propertiesToFetch = [keyName]
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        
        if let results = try? context.fetch(request) {
            let categories = results.flatMap({ $0[keyName] as? String })
            return categories.sorted()
        }
        
        return []
    }
}
