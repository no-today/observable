//
//  AssetItemService.swift
//  Observable
//
//  Created by whoog on 2024/11/11.
//

import Foundation
import SwiftData

struct AssetManager {
    
    static func insertAsset(_ context: ModelContext, category: AssetCategory, name: String, amount: Double, createdDate: Date) -> PersistentIdentifier {
        let asset = Asset(category: category, name: name, amount: amount, createdDate: createdDate, lastModified: createdDate)
        context.insert(asset)
        context.insert(AssetChangeLog(belong: asset, amount: asset.amount, date: asset.createdDate))
        
        try? context.save()
        return asset.persistentModelID
    }
    
    static func updateAmount(_ context: ModelContext, assetId: PersistentIdentifier, name: String? = nil, amount: Double? = nil, date: Date) {
        if let asset = context.model(for: assetId) as? Asset {
            updateAmount(context, asset: asset, name: name, amount: amount, date: date)
        }
    }
    
    static func updateAmount(_ context: ModelContext, asset: Asset, name: String? = nil, amount: Double? = nil, date: Date) {
        if let name = name, name != "" {
            asset.name = name
            asset.lastModified = date
        }
        if let amount = amount {
            if asset.lastModified < date || (asset.amount == 0 && amount != 0) {
                asset.amount = amount
                asset.lastModified = date
            }
            
            context.insert(AssetChangeLog(belong: asset, amount: amount, date: date))
        }
        
        try? context.save()
    }
    
    static func deleteAsset(_ context: ModelContext, asset: Asset) {
        context.delete(asset)
        try? context.delete(model: AssetChangeLog.self, where: AssetChangeLog.predicateFor(.filterByAssetId(assetId: asset.id)))
        try? context.save()
    }
    
    static func updateLog(_ context: ModelContext, changeLog: AssetChangeLog, amount: Double? = nil, date: Date) {
        if let amount = amount {
            changeLog.amount = amount
        }
        changeLog.date = date
        
        resetAmount(context, changeLog.belong)
        try? context.save()
    }
    
    static func deleteLog(_ context: ModelContext, changeLog: AssetChangeLog) {
        let asset = changeLog.belong
        context.delete(changeLog)
        
        resetAmount(context, asset)
        try? context.save()
    }
    
    /// 更新、删除数据后将最新的日志同步到主数据
    /// 如果没有日志了，则置为0
    fileprivate static func resetAmount(_ context: ModelContext, _ asset: Asset) {
        let logs = DataQuery.query(context, as: AssetChangeLog.self, predicate: AssetChangeLog.predicateFor(.filterByAssetId(assetId: asset.id)), sortBy: [SortDescriptor<AssetChangeLog>(\.date, order: .reverse)], size: 2) // 这儿不能设置为1，感觉像是 deleted 也会占用一个 limit，只是查不出来了
        
        if logs.isEmpty {
            asset.amount = 0
            asset.lastModified = .now
        } else {
            asset.amount = logs[0].amount
            asset.lastModified = logs[0].date
        }
    }
}
