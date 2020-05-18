//
//  SearchViewModel.swift
//  WynkDemo
//
//  Created by Nitin Upadhyay on 16/05/20.
//  Copyright © 2020 Nitin Upadhyay. All rights reserved.
//

import Foundation
import UIKit

protocol SearchViewModelProtocol {
    var title: String { get set }
    var placeholder: String { get set }
    var reuseIdentifier: String { get set }
    var numberOfCellsInRow: Int { get set }
    var spaceBetweenCells: Int { get set }
    var persistance: PersistanceProtocol { get set }
    var minimumSpacing: CGFloat { get set }
    var edgeInsetPadding: CGFloat { get set }

}

public struct SearchViewModel: SearchViewModelProtocol {
    var title: String
    var placeholder: String
    var reuseIdentifier: String
    var numberOfCellsInRow: Int
    var spaceBetweenCells: Int
    var persistance: PersistanceProtocol
    var minimumSpacing: CGFloat
    var edgeInsetPadding: CGFloat

    init(title: String, placeholder: String, reuseIdentifier: String, numberOfCellsInRow: Int, spaceBetweenCells: Int,
        persistance: PersistanceProtocol, minimumSpacing: CGFloat, edgeInsetPadding: CGFloat) {
        self.title = title
        self.placeholder = placeholder
        self.reuseIdentifier = reuseIdentifier
        self.numberOfCellsInRow = numberOfCellsInRow
        self.spaceBetweenCells = spaceBetweenCells
        self.persistance = persistance
        self.minimumSpacing = minimumSpacing
        self.edgeInsetPadding = edgeInsetPadding
    }
}
