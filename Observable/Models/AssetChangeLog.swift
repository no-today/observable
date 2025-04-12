//
//  AssetChangeLog.swift
//  Observable
//
//  Created by whoog on 2024/11/11.
//

import Foundation
import SwiftData

@Model
final class AssetChangeLog: Identifiable, Codable, Comparable {
    @Relationship var belong: Asset
    
    var amount: Double
    var date: Date
    var change: Double
    
    init(belong: Asset, amount: Double, date: Date, change: Double = 0) {
        self.belong = belong
        self.amount = amount
        self.date = date
        self.change = change
    }
    
    static func < (lhs: AssetChangeLog, rhs: AssetChangeLog) -> Bool {
        lhs.date > rhs.date
    }
    
    enum CodingKeys: CodingKey {
        case belong
        case amount
        case date
        case change
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        belong = try container.decode(Asset.self, forKey: .belong)
        amount = try container.decode(Double.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        change = try container.decode(Double.self, forKey: .change)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encode(change, forKey: .change)
    }
}

public enum AssetChangeLogPredicate: Sendable {
    case filterByAssetId(assetId: PersistentIdentifier)
    case filterByDateLessThan(date: Date)
    case filterByAssetIdAndDateLessThanEqual(assetId: PersistentIdentifier, date: Date)
}

extension AssetChangeLog {
    
    static func predicateFor(_ filter: AssetChangeLogPredicate) -> Predicate<AssetChangeLog>? {
        var result: Predicate<AssetChangeLog>?
        switch filter {
        case .filterByAssetId(let assetId):
            result = #Predicate<AssetChangeLog> { item in
                // https://stackoverflow.com/a/76669189/12679246
                // #Predicate 的闭包必须是一个单一的、确定的表达式，这样它才能转换为底层的 SQL 或 Core Data 查询。
                // 意思就是说用 if 会 crash
                // 这个里面不能用 .id
                item.belong.persistentModelID == assetId
            }
        case .filterByDateLessThan(let date):
            result = #Predicate<AssetChangeLog> { item in
                item.date < date
            }
        case .filterByAssetIdAndDateLessThanEqual(let assetId, let date):
            result = #Predicate<AssetChangeLog> { item in
                item.belong.persistentModelID == assetId && item.date <= date
            }
        }
        
        return result
    }
    
    /// 从更新快照堆中找到某个时间点的金额
    /// - Parameter logs: 降序排列的更新快照
    /// - Parameter atDate: 目标时间点
    /// - Returns: 当时的金额
    public static func amountAt(logs: [AssetChangeLog], atDate: Date) -> Double? {
        for log in logs {
            if log.date <= atDate {
                return log.amount
            }
        }
        
        return nil
    }
    
    public static func groupByMonth(logs: [AssetChangeLog], _ defKey: String, _ defVal: Double = 0) -> [Pair<String, Double>] {
        if logs.isEmpty {
            return [Pair(key: defKey, val: defVal)]
        }
        
        let grouped = Dictionary(grouping: logs, by: { $0.date.yyyyMM })
        return grouped.map { (key: String, val: [AssetChangeLog]) in
            Pair(key: key, val: val.first?.amount ?? 0)
        }
    }
}
