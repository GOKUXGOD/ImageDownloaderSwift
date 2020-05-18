//
//  SearchApiService.swift
//  WynkDemo
//
//  Created by Nitin Upadhyay on 16/05/20.
//  Copyright © 2020 Nitin Upadhyay. All rights reserved.
//

import Foundation

public final class SearchApiService: SearchApiServiceProtocol {
    private let networkService: PixabayImagesClient

    init(networkService: PixabayImagesClient) {
        self.networkService = networkService
    }

    public func fetchSearchResult(endpoint: SearchEndpoint, success: ((SearchData) -> Void)?, failure: ((APIError) -> Void)?) {
        networkService.getFeed(endpoint: endpoint) { result in
            switch result {
            case .success(let items):
                success?(items!)
            case .failure(let error):
                failure?(error)
            }
        }
    }
}

