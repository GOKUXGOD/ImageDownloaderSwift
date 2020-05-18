//
//  PersistanceProtocol.swift
//  WynkDemo
//
//  Created by Nitin Upadhyay on 17/05/20.
//  Copyright © 2020 Nitin Upadhyay. All rights reserved.
//

import Foundation

public protocol PersistanceProtocol {
    func set(value: [PreviousSearchData]?, for key: PersistanceKey)
    func getvalue(for key: PersistanceKey) -> [PreviousSearchData]?
}

public enum PersistanceKey: String {
    case recentSearches
}

public protocol DataStoreConstantProtocol {
    var rawValue: String { get }
}

public protocol DataStoreSharedConstantProtocol: DataStoreConstantProtocol {
}

public protocol StorageProtocol {
    var previousSearches: [PreviousSearchData]? { get set }
}

public class Storage: StorageProtocol {
    private struct PrivateConstants {
        static let dataStoreDir: String = "Preferences"
        static let separator: String = "/"
        static let fileExtension: String = ".plist"
        static let sharedSuffix: String = "_shared"
        static let userSuffix: String = "_user"
    }

    private var sharedFilePath: String?
    private var sharedDictionary: [String: Any]?
    private var sharedDict: [String: Any] {
        get {
            if sharedDictionary == nil {
                sharedDictionary = loadDictionary(filePath: sharedFilePath)
            }
            return sharedDictionary!
        }
        set {
            sharedDictionary = newValue
        }
    }

    private func loadDictionary(filePath: String?) -> [String: Any] {
        guard let filePath = filePath,
            let dictionary = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [String: Any] else {
                return [String: Any]()
        }
        return dictionary
    }

    public enum SharedKey: String, DataStoreSharedConstantProtocol {
        case lastSearchedItems = "LAST_SEARCH_ITEMS"
    }

    public init() {
        // create Preferences dir at Library if not exists
        guard let libraryPath = FileManager.default.sharedStoragePath() else {
            return
        }
        let toFolderPath = libraryPath.appending(PrivateConstants.separator)
            .appending(PrivateConstants.dataStoreDir)
        let toFolder = URL(fileURLWithPath: toFolderPath)

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: toFolderPath) {
            do {
                try fileManager.createDirectory(at: toFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // errorLog(error)
                return
            }
        }

        sharedFilePath = toFolderPath.appending(PrivateConstants.separator)
            .appending(PrivateConstants.sharedSuffix)
            .appending(PrivateConstants.fileExtension)
    }
    
    public var previousSearches: [PreviousSearchData]? {
        get {
            let jsonDecoder = JSONDecoder()
            if let jsonData = value(forKey: SharedKey.lastSearchedItems) as? Data,
                let appDb = try? jsonDecoder.decode([PreviousSearchData].self, from: jsonData) {
                return appDb
            }

            return nil
        }
        set(newValue) {
            if let newValue = newValue {
                let jsonEncoder = JSONEncoder()
                if let jsonData = try? jsonEncoder.encode(newValue) {
                    set(jsonData, forKey: SharedKey.lastSearchedItems)
                }
            }
        }
    }

    public func set(_ value: Any, forKey: DataStoreConstantProtocol) {
        if forKey is DataStoreSharedConstantProtocol {
            sharedDict.updateValue(value, forKey: forKey.rawValue)
        }
    }

    public func value(forKey key: DataStoreConstantProtocol) -> Any? {
        guard let dict = dict(forKey: key) else {
            return nil
        }

        return dict[key.rawValue]
    }

    private func dict(forKey: DataStoreConstantProtocol) -> [String: Any]? {
        if forKey is DataStoreSharedConstantProtocol {
            return sharedDict
        }
        return nil
    }
}

extension FileManager {
    public func sharedStoragePath() -> String? {
        print("FileManager.default \(FileManager.default.currentDirectoryPath)")
        let fileManager = FileManager.default
        guard let libraryDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }
        let filePath = libraryDirectory.appendingPathComponent("ImageDownloader")
        if !fileManager.fileExists(atPath: filePath.path) {
            do {
                try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                return filePath.path
            } catch {
                print("Couldn't create document directory")
                return nil
            }
        }
        return filePath.path
    }
}
