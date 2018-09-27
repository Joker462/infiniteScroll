//
//  RecipesViewModel.swift
//  InfiniteScroll
//
//  Created by Son HD on 9/6/18.
//  Copyright © 2018 joker. All rights reserved.
//

import Foundation

final class RecipesViewModel {
    
    // Variables
    private var page: Int = 0
    fileprivate var isFreshing: Bool = false
    fileprivate lazy var downloadsInProgress: [IndexPath: Operation] = [:]
    fileprivate lazy var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Donwload queue"
        return queue
    }()
    fileprivate lazy var filtrationsInProgress: [IndexPath: Operation] = [:]
    fileprivate lazy var filtrationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Image Filtration queue"
        return queue
    }()
    
    var recipes: [RecipeItemViewModel] = []
    
    // Output
    weak var output: RecipesViewModelOutput?
    
    // Input
    func loadingRecipes() {
        page += 1
        fetchRecipes(page: page)
    }
    
    func willDisplay(cell: RecipesTableViewCell, atIndexPath: IndexPath) {
        cell.configure(recipes[atIndexPath.row])
    }
    
    // MARK: - Operation methods -
    func startOperations(at indexPath: IndexPath) {
        let recipe = recipes[indexPath.row]
        // Check photo state of recipe item view model
        switch recipe.state {
        case .new:
            startDownloadOperation(recipe, at: indexPath)
            break
        case .downloaded:
            startFiltrationOperation(recipe, at: indexPath)
            break
        default:
            break
        }
    }
    
    func suspendAllOperations() {
        downloadQueue.isSuspended = true
        filtrationQueue.isSuspended = true
    }
    
    func resumeAllOperations() {
        downloadQueue.isSuspended = false
        filtrationQueue.isSuspended = false
    }
    
    func loadImagesForOnScreen(at visibleIndexPaths: [IndexPath]?) {
        if let visibleIndexPaths = visibleIndexPaths {
            var allPendingOperations = Set(downloadsInProgress.keys)
            allPendingOperations.formUnion(filtrationsInProgress.keys)
            
            let visiblePaths = Set(visibleIndexPaths)
            var toBeCancelled = allPendingOperations
            toBeCancelled.subtract(visiblePaths)
            
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations)
            
            toBeCancelled.forEach {
                if let pendingDownload = self.downloadsInProgress[$0] {
                    pendingDownload.cancel()
                }
                self.downloadsInProgress.removeValue(forKey: $0)
                
                if let pendingFiltration = self.filtrationsInProgress[$0] {
                    pendingFiltration.cancel()
                }
                self.filtrationsInProgress.removeValue(forKey: $0)
            }
            
            toBeStarted.forEach(startOperations)
        }
    }
}


// MARK: - Private methods -
private extension RecipesViewModel {
    func fetchRecipes(page: Int) {
        let url = URL(string: "http://food2fork.com/api/search")!
        let urlRequest = URLRequest(url: url)
        let encodedURL = urlRequest.encode(with: ["key": "77148f0c76810849ad9e08754e3bd327",
                                                  "page": "\(page)"])
        if isFreshing {
            return
        }
        isFreshing = true
        output?.isFreshing(isFreshing)
        URLSession.shared.dataTask(with: encodedURL) { [weak self] (data, response, error) in
            self?.isFreshing = false
            if let data = data {
                self?.handle(data)
            }
        }.resume()
    }
    
    private func handle(_ data: Data) {
        do {
            let recipes = try JSONDecoder().decode(Recipes.self, from: data)
            self.recipes.append(contentsOf: recipes.recipeItems.map { RecipeItemViewModel(recipeItem: $0) })
            DispatchQueue.main.async {
                self.output?.isFreshing(self.isFreshing)
                if self.page > 1 {
                    let indexPathsToReload = self.calculateIndexPathsToReload(from: recipes.recipeItems)
                    self.output?.addTableViewCell(with: indexPathsToReload)
                } else {
                    self.output?.addTableViewCell(with: .none)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func calculateIndexPathsToReload(from newRecipes: [RecipeItem]) -> [IndexPath] {
        let startIndex = recipes.count - newRecipes.count
        let endIndex = startIndex + newRecipes.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
    func startDownloadOperation(_ recipe: RecipeItemViewModel, at indexPath: IndexPath) {
        guard downloadsInProgress[indexPath] == nil else { return }
        
        let downloader = ImageDownloader(recipe)
        downloader.completionBlock = {
            if downloader.isCancelled { return }
            
            DispatchQueue.main.async {
                self.downloadsInProgress.removeValue(forKey: indexPath)
                self.output?.reloadTableView(at: [indexPath])
            }
        }
        downloadsInProgress[indexPath] = downloader
        downloadQueue.addOperation(downloader)
    }
    
    func startFiltrationOperation(_ recipe: RecipeItemViewModel, at indexPath: IndexPath) {
        guard filtrationsInProgress[indexPath] == nil else { return }
        
        let filterer = ImageFiltration(recipe)
        filterer.completionBlock = {
            if filterer.isCancelled { return }
            
            DispatchQueue.main.async {
                self.filtrationsInProgress.removeValue(forKey: indexPath)
                self.output?.reloadTableView(at: [indexPath])
            }
        }
        filtrationsInProgress[indexPath] = filterer
        filtrationQueue.addOperation(filterer)
    }
}

protocol RecipesViewModelOutput: class {
    func showError(message: String)
    func addTableViewCell(with newIndexPathReload: [IndexPath]?)
    func reloadTableView(at indexPaths: [IndexPath])
    func isFreshing(_ bool: Bool)
}

typealias Parameters = [String: String]

extension URLRequest {
    func encode(with parameters: Parameters?) -> URLRequest {
        guard let parameters = parameters else {
            return self
        }
        
        var encodedURLRequest = self
        
        if let url = self.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            !parameters.isEmpty {
            var newUrlComponents = urlComponents
            let queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            newUrlComponents.queryItems = queryItems
            encodedURLRequest.url = newUrlComponents.url
            return encodedURLRequest
        } else {
            return self
        }
    }
}
