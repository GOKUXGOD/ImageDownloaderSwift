//
//  PreviousSearchData.swift
//  WynkDemo
//
//  Created by Nitin Upadhyay on 17/05/20.
//  Copyright © 2020 Nitin Upadhyay. All rights reserved.
//

import Foundation
public protocol PreviousSearchDataProtocol {
    var title: String { get set }
    var photos: [SearchItem] { get set }
}

public struct PreviousSearchData: PreviousSearchDataProtocol, Codable {
    public var title: String
    public var photos: [SearchItem]
    
    public init(title: String, photos: [SearchItem]) {
        self.title = title
        self.photos = photos
    }
}
