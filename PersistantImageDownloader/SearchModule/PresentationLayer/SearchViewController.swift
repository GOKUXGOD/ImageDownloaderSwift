//
//  SearchViewController.swift
//  WynkDemo
//
//  Created by Nitin Upadhyay on 16/05/20.
//  Copyright © 2020 Nitin Upadhyay. All rights reserved.
//

import Foundation
import UIKit

fileprivate struct PrivateConstants {
    static let headerOffset: CGFloat = 80
    static let edgeInsets =  UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
}

class SearchViewController: UIViewController, SearchResultsInterfaceProtocol {
    var presenter: SearchResultsPresenterProtocol
    var recentSearchesView: RecentSearchesInterface
    private var dataSource: [SearchItem] = []
    private var numberOfItemsInRow: CGFloat = 2
    private var minimumSpacing: CGFloat = 5
    private var edgeInsetPadding: CGFloat = 10

    private var viewModel: SearchViewModelProtocol
    private var cacheManager: CacheProtocol
    private var currentSearchText = ""
    
    private let searchController: UISearchController = {
        return UISearchController(searchResultsController: nil)
    }()

    private var centerLoader: UIActivityIndicatorView = {
        let centerLoader = UIActivityIndicatorView(style: .medium)
        centerLoader.translatesAutoresizingMaskIntoConstraints = false
        centerLoader.isHidden = true
        return centerLoader
    }()

    private lazy var collectionViewLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private var recentSearchesViewController: RecentSearchesViewController {
        return recentSearchesView as! RecentSearchesViewController
    }

    init(presenter: SearchResultsPresenterProtocol, viewModel: SearchViewModelProtocol,
         recentSearchesView: RecentSearchesInterface, cacheManager: CacheProtocol) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.recentSearchesView = recentSearchesView
        self.cacheManager = cacheManager

        super.init(nibName: nil, bundle: nil)

        self.presenter.interface = self
        self.recentSearchesView.delegate = self
        setUpView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func setUpView() {
        setUpCollectionView()
        setUpSearchController()
        setUpLoader()
        registerNibs()
        setUpRecentSearches()
    }

    private func setUpCollectionView() {
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        var constraints = [NSLayoutConstraint]()
        constraints.append(collectionView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        constraints.append(collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        NSLayoutConstraint.activate(constraints)
    }

    private func setUpLoader() {
        view.addSubview(centerLoader)
        var constraints = [NSLayoutConstraint]()
        constraints.append(centerLoader.centerYAnchor.constraint(equalTo: view.centerYAnchor))
        constraints.append(centerLoader.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        NSLayoutConstraint.activate(constraints)
    }

    private func setUpRecentSearches() {
        view.addSubview(recentSearchesViewController.view)
        var constraints = [NSLayoutConstraint]()
        recentSearchesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(recentSearchesViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: PrivateConstants.headerOffset))
        constraints.append(recentSearchesViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        constraints.append(recentSearchesViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(recentSearchesViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        NSLayoutConstraint.activate(constraints)
    }

    private func setUpSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = viewModel.placeholder
        navigationItem.titleView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.searchTextField.clearButtonMode = .never
        definesPresentationContext = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(handleMenuTap))
    }

    private func registerNibs() {
        collectionView.register(SearchResultsCell.self, forCellWithReuseIdentifier: viewModel.reuseIdentifier)
    }

    @objc func handleMenuTap() {
        showOptions()
    }

    func showOptions() {
        let alert = UIAlertController(title: "Select Grid", message: "Please Select an Option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "2X2 Gird", style: .default, handler: { [weak self](_) in
            print("selected 2X2 Gird")
            self?.reloadLayout(gridSize: 2)
        }))
        
        alert.addAction(UIAlertAction(title: "3X3 Gird", style: .default, handler: { [weak self](_) in
            print("selected 3X3 Gird")
            self?.reloadLayout(gridSize: 3)
        }))
        
        alert.addAction(UIAlertAction(title: "4X4 Gird", style: .default, handler: { [weak self](_) in
            print("selected 4X4 Gird")
            self?.reloadLayout(gridSize: 4)
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("dismiss")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    private func showRecentSearches() {
        recentSearchesViewController.view.isHidden = false
    }
    
    private func hideRecentSearches() {
        recentSearchesViewController.view.isHidden = true
    }

    private func reloadLayout(gridSize: CGFloat) {
        collectionViewLayout.invalidateLayout()
        numberOfItemsInRow = gridSize
        collectionView.reloadData()
    }

    func setUpView(with data: [SearchItem]) {
        centerLoader.stopAnimating()
        if dataSource.isEmpty {
            dataSource = data
            collectionView.reloadData()
            if data.isEmpty {
                self.presentAlert(withTitle: "No Content found", message: "Try searching something else")
            }
        } else {
            setUpPaginationData(items: data)
        }
    }

    private func setUpPaginationData(items: [SearchItem]) {
        let indexPathsToReload = calculateIndexPathToReloadFrom(newAssets: items)
        dataSource.append(contentsOf: items)
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: indexPathsToReload)
        }, completion: nil)
    }

    private func calculateIndexPathToReloadFrom(newAssets: [SearchItem]) -> [IndexPath] {
        let startIndex = dataSource.count
        let endIndex = startIndex + newAssets.count

        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }

    private func perfromSearchFor(text: String) {
        cacheManager.pendingOperations.cancelAllOperations()
        dataSource = []
        collectionView.reloadData()
        centerLoader.startAnimating()
        presenter.searchText(text)
        hideRecentSearches()
    }

    private func startOperations(for searchItem: SearchItem, at indexPath: IndexPath, increasePriority: Bool) {
        switch (searchItem.state) {
        case .new:
            startDownload(for: searchItem, at: indexPath)
            if increasePriority {
                self.increasePriority(for: searchItem, at: indexPath)
            }
        case .downloaded, .failed:
            print("nothing required")
        }
    }

    func increasePriority(for searchItem: SearchItem, at indexPath: IndexPath) {
        guard let url = searchItem.normalImageUrl, !url.isEmpty, let operation = cacheManager.pendingOperations.downloadsInProgress[url] else {
            return
        }
        operation.queuePriority = .veryHigh
        print("priority Increased")
    }

    func startDownload(for searchItem: SearchItem, at indexPath: IndexPath) {
        guard let url = searchItem.normalImageUrl, !url.isEmpty, cacheManager.pendingOperations.downloadsInProgress[url] == nil else {
            return
        }
        cacheManager.startDownloadForItem(item: DownlodableItem(searchItem: searchItem)) { [weak self] (image, error) in
            DispatchQueue.main.async {
                if let cell = self?.collectionView.cellForItem(at: indexPath) as? SearchResultsCell {
                    cell.imageView.image = image
                    cell.loader.stopAnimating()
                    self?.dataSource[indexPath.row].state = .downloaded
                    self?.dataSource[indexPath.row].image = image
                }
            }
        }
    }

    deinit {
        print("vc deinit")
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cacheManager.pendingOperations.cancelAllOperations()
        searchBar.text = ""
        dataSource = []
        collectionView.reloadData()
        if let searches = viewModel.persistance.getvalue(for: .recentSearches) {
            recentSearchesView.updateDatasource(searches)
        }
        showRecentSearches()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text, text != currentSearchText {
            currentSearchText = text
            perfromSearchFor(text: text)
        }
    }
}

extension SearchViewController: RecentSearchesViewDelegate {
    func didSelectRecentSearch(_ searchItem: PreviousSearchData) {
        searchController.searchBar.text = searchItem.title
        perfromSearchFor(text: searchItem.title)
    }
}

extension SearchViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewModel.reuseIdentifier, for: indexPath) as? SearchResultsCell {
            return cell
        }
        fatalError()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if dataSource.count == indexPath.row + 1, let text = searchController.searchBar.text {
            presenter.searchText(text)
        }
        
        let assetDetails = dataSource[indexPath.row]
        if let cell = cell as? SearchResultsCell {
            switch assetDetails.state {
            case .new:
                cell.loader.startAnimating()
                if !collectionView.isDragging && !collectionView.isDecelerating {
                    startOperations(for: assetDetails, at: indexPath, increasePriority: false)
                }
                cell.imageView.image = UIImage(named: "placeholder")
                cell.loader.startAnimating()
            case .downloaded:
                cell.loader.stopAnimating()
                cell.imageView.image = assetDetails.image
            case .failed:
                cell.loader.stopAnimating()
                cell.imageView.image = UIImage(named: "failed")
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row < dataSource.count, let url = dataSource[indexPath.row].normalImageUrl, !url.isEmpty, let operation =  cacheManager.pendingOperations.downloadsInProgress[url]  {
            operation.queuePriority = .veryLow
            print("priority decreases")
        }
    }
}

extension SearchViewController: UICollectionViewDelegate {
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = PrivateConstants.edgeInsets
        viewModel.edgeInsetPadding = inset.left+inset.right
        return inset
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return viewModel.minimumSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return viewModel.minimumSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - (numberOfItemsInRow - 1) * viewModel.minimumSpacing - viewModel.edgeInsetPadding) / numberOfItemsInRow

        return CGSize(width: width, height: width)
    }
}

extension SearchViewController {
    // MARK: - scrollview delegate methods
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
       suspendAllOperations()
     }
     
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
       if !decelerate {
         loadImagesForVisibleCells()
         resumeAllOperations()
       }
     }
     
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
       loadImagesForVisibleCells()
       resumeAllOperations()
     }

     // MARK: - operation management

    func suspendAllOperations() {
        cacheManager.pendingOperations.downloadQueue.isSuspended = true
     }
     
    func resumeAllOperations() {
       cacheManager.pendingOperations.downloadQueue.isSuspended = false
     }
     
    func loadImagesForVisibleCells() {
        let pathsArray = collectionView.indexPathsForVisibleItems
        for indexPath in pathsArray {
            let recordToProcess = dataSource[indexPath.row]
            startOperations(for: recordToProcess, at: indexPath, increasePriority: true)
        }
    }
}
