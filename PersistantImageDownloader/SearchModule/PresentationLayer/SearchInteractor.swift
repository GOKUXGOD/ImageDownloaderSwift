//
//  SearchInteractor.swift
//  WynkDemo
//
//  Created by Nitin Upadhyay on 16/05/20.
//  Copyright © 2020 Nitin Upadhyay. All rights reserved.
//

import Foundation

final class SearchInteractor: SearchResultsInteractorInputProtocol {
    var presenter: SearchResultsInteractorOutputProtocol?
    private let searchService: SearchServiceProtocol!

    init(searchService: SearchServiceProtocol) {
        self.searchService = searchService
    }

    func performSearchFor(_ text: String, offset: Int, size: Int) {
        let encodedString = text.replacingOccurrences(of: " ", with: "+")
        searchService.fetchSearchResult(searchKey: encodedString, offset: offset, size: size, success: { [weak self] searchData in
            guard let sSelf = self else {
                return
            }
            sSelf.presenter?.updateSearchWithData(searchData)
        }) { [weak self] error in
            guard let sSelf = self else {
                return
            }
            sSelf.presenter?.handleError(error, retryBlock: {})
        }
    }
}
