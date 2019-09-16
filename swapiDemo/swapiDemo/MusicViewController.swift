//
//  MusicViewController.swift
//  swapiDemo
//
//  Created by Saleh on 9/13/19.
//  Copyright © 2019 Saleh. All rights reserved.
//

import UIKit
import swapi

class MusicViewController: UITableViewController, UISearchBarDelegate {

    var results: [Result] = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let result: Result = results[indexPath.row]
        cell.textLabel?.text = result.trackName
        cell.detailTextLabel?.text = result.artist

        return cell
    }
    

   
    // MARK: - SearchBar Delegate
    

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
         if let searchTerm = searchBar.text {
                   search(term: searchTerm)
         }
        searchBar.resignFirstResponder()
    }
    
    // MARK: - API Call
    
    func search(term: String) {
        
        APIRequester.shared.debugLogging = true
        
        APIRequester.shared.request(endpoint: MusicAPI.search(term: term.replacingOccurrences(of: " ", with: "+"), limit: 25), deserialize: ResultResponse.self) { (result) in
            DispatchQueue.main.async {
            
            switch result {
            case let .success(response):
                if let searchResults = response {
                    self.results = searchResults.results
                    self.tableView.reloadData()
                }
                break
            case let .failure(error):
                switch error.innerError {
                case .connectionError:
                        let avc = UIAlertController(title: "Error", message: "Please check your internet connection", preferredStyle: .alert)
                        avc.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action) in
                            
                        }))
                        self.present(avc, animated: true, completion: nil)
                    
                    break
                case .badRequest:
                    break
                case let .other(errDetails):
                    let avc = UIAlertController(title: "API Error", message: errDetails.localizedDescription, preferredStyle: .alert)
                    avc.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action) in
                        
                    }))
                    self.present(avc, animated: true, completion: nil)
                default:
                    break;
                }
                break
                
            }
        }
        }
    }

}
