//
//  Asset.swift
//  Observable
//
//  Created by whoog on 2024/11/1.
//

import Foundation
import SwiftData
import CoreTransferable

@Model
class Asset: Identifiable, Codable {
    
    @Attribute var _category: AssetCategory.RawValue
    @Transient var category: AssetCategory {
        get { AssetCategory(rawValue: _category)! }
        set { _category = newValue.rawValue }
    }
    
    var name: String
    var amount: Double
    
    var createdDate: Date
    var lastModified: Date
    
    init(category: AssetCategory, name: String, amount: Double = 0, createdDate: Date = .now, lastModified: Date = .now) {
        self.name = name
        self.amount = amount
        self.createdDate = createdDate
        self.lastModified = lastModified
        self._category = category.rawValue
    }
    
    /// MARK: Codable
    
    enum CodingKeys: CodingKey {
        case category
        case name
        case amount
        case createdDate
        case lastModified
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _category = try container.decode(String.self, forKey: .category)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_category, forKey: .category)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(lastModified, forKey: .lastModified)
    }
}

/// https://www.youtube.com/watch?v=LLKLa8IgK3I&ab_channel=Kavsoft
struct AssetTransferable: Transferable {
    var assets: [Asset]
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode($0.assets)
        }
    }
}

enum AssetPredicate: Sendable {
    case filterByCategory(category: AssetCategory)
}

extension Asset {
    static func predicateFor(_ filter: AssetPredicate) -> Predicate<Asset>? {
        var result: Predicate<Asset>?
        switch filter {
        case .filterByCategory(let category):
            result = #Predicate<Asset> { item in
                // https://stackoverflow.com/a/76669189/12679246
                // #Predicate 的闭包必须是一个单一的、确定的表达式，这样它才能转换为底层的 SQL 或 Core Data 查询。
                // 意思就是说用 if 会 crash
                item._category == category.rawValue
            }
        }
        
        return result
    }
}

//let createdDate = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
let createdDate = Date.now
let mockDataAssetItems = [
    Asset(category: .liabilities, name: "信用卡", amount: -3000, createdDate: createdDate),
    Asset(category: .liabilities, name: "房屋贷款", amount: -500000, createdDate: createdDate),
    Asset(category: .liabilities, name: "车辆贷款", amount: -40000, createdDate: createdDate),
    Asset(category: .liabilities, name: "个人贷款", amount: -30000, createdDate: createdDate),
    
    Asset(category: .fixedAssets, name: "房产(自住)", amount: 800000, createdDate: createdDate),
    Asset(category: .fixedAssets, name: "汽车", amount: 50000, createdDate: createdDate),
    
    Asset(category: .liquidAssets, name: "后备隐藏能源", amount: 50000, createdDate: createdDate),
    Asset(category: .receivables, name: "借给他人的钱", amount: 20000, createdDate: createdDate),
    Asset(category: .receivables, name: "借给他人的钱1", amount: 20000, createdDate: createdDate),
    Asset(category: .receivables, name: "借给他人的钱2", amount: 20000, createdDate: createdDate),
    Asset(category: .receivables, name: "借给他人的钱3", amount: 20000, createdDate: createdDate),
    Asset(category: .receivables, name: "借给他人的钱4", amount: 20000, createdDate: createdDate),
    Asset(category: .receivables, name: "借给他人的钱5", amount: 20000, createdDate: createdDate),
]
