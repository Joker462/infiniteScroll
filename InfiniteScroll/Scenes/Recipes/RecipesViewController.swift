//
//  RecipesViewController.swift
//  InfiniteScroll
//
//  Created by Son HD on 9/6/18.
//  Copyright © 2018 joker. All rights reserved.
//

import UIKit

final class RecipesViewController: UIViewController {

    // IBOutlets
    @IBOutlet var tableView: UITableView!
    
    // Variable
    fileprivate let viewModel = RecipesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindingViewModel()
        viewModel.loadingRecipes()
    }
}


// MARK: - Private methods -
private extension RecipesViewController {
    func configureUI() {
        // Navigation
        title = "Recipes"
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func bindingViewModel() {
        viewModel.output = self
    }
}


// MARK: - Recipes view model output -
extension RecipesViewController: RecipesViewModelOutput {
    func showError(message: String) {
        if !message.isEmpty {
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
            
            present(alertController, animated: true)
        }
    }
    
    func addTableViewCell(with newIndexPathReload: [IndexPath]?) {
        guard let newIndexPathReload = newIndexPathReload else {
            tableView.reloadData()
            return
        }
        
        tableView.beginUpdates()
        tableView.insertRows(at: newIndexPathReload, with: .automatic)
        tableView.endUpdates()
    }
    
    func isFreshing(_ bool: Bool) {
        if bool {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            spinner.startAnimating()
            spinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 90)
            
            tableView.tableFooterView = spinner
        } else {
            tableView.tableFooterView = nil
        }
    }
    
    func reloadTableView(at indexPaths: [IndexPath]) {
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }
}

// MARK: - UITableViewDataSource -
extension RecipesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.recipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipesTableViewCell", for: indexPath) as! RecipesTableViewCell
        return cell
    }
}

// MARK: - UITableViewDelegate -
extension RecipesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? RecipesTableViewCell else { return }
        viewModel.willDisplay(cell: cell, atIndexPath: indexPath)
        
        if !tableView.isDragging && !tableView.isDecelerating {
            viewModel.startOperations(at: indexPath)
        }
        
        // Load more if scroll to latest of recipes
        if indexPath.row == viewModel.recipes.count - 1 {
            viewModel.loadingRecipes()
        }
    }
}

// MARK: - UIScrollViewDelegate -
extension RecipesViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.suspendAllOperations()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewModel.loadImagesForOnScreen(at: tableView.indexPathsForVisibleRows)
            viewModel.resumeAllOperations()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewModel.loadImagesForOnScreen(at: tableView.indexPathsForVisibleRows)
        viewModel.resumeAllOperations()
    }
}
