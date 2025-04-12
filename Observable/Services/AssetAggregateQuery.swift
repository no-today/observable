//
//  AssetAggregateQuery.swift
//  Observable
//
//  Created by whoog on 2024/11/14.
//

import Foundation
import SwiftData
import SwiftUICore

struct AssetAggregateQuery {
    
    /// Aggregate Query
    
    static func amountAt(_ context: ModelContext, assetId: PersistentIdentifier, date: Date) -> (amount: Double, modifiedTime: Date?) {
        DataQuery.queryOne(context, as: AssetChangeLog.self, predicate: AssetChangeLog.predicateFor(.filterByAssetIdAndDateLessThanEqual(assetId: assetId, date: date)), sortBy: [SortDescriptor<AssetChangeLog>(\.date, order: .reverse)])
            .map { ($0.amount, $0.date) } ?? (0 , nil)
    }
    
    static func amountAt(_ context: ModelContext, category: AssetCategory? = nil, date: Date) -> (amount: Double, modifiedTime: Date?) {
        let predicate = category.flatMap { Asset.predicateFor(.filterByCategory(category: $0)) }
        var modifiedTime: Date? = nil
        
        let amount = DataQuery.query(context, as: Asset.self, predicate: predicate)
            .map { asset -> Double in
                let (amount, modified) = amountAt(context, assetId: asset.id, date: date)
                if let modified = modified, (modifiedTime ?? .distantPast) < modified {
                    modifiedTime = modified
                }
                
                return amount
            }
            .reduce(0, +)
        
        return (amount, modifiedTime)
    }
    
    /// ------------------------------------------------------------
    
    static func summary(_ items: [Asset]) -> (totalAssets: Double, liabilities: Double, netAssets: Double, debtRatio: Double, lastModified: Date?) {
        let totalAssets = asset(items)
        let liabilities = liabilities(items)
        
        return (totalAssets, liabilities, totalAssets + liabilities, abs(liabilities) / totalAssets * 100, items.sorted(by: \.lastModified).last?.lastModified)
    }
    
    static func asset(_ items: [Asset], _ filter: (Asset) -> Bool = { $0.category.isAsset }) -> Double {
        return items.filter(filter).reduce(0, { $0 + $1.amount })
    }
    
    static func liabilities(_ items: [Asset]) -> Double {
        return items.filter {  $0.category.isLiability }.reduce(0, { $0 + $1.amount })
    }
    
    static func sumByCategory(_ items: [Asset], _ category: AssetCategory) -> Double {
        return items.filter {  $0.category == category }.reduce(0, { $0 + $1.amount })
    }
    
    /// 资产摘要卡片数据
    /// 负债是负数, 负债与上月的差值则是 abs 后再计算的
    static func aggregateForSummary(_ context: ModelContext) -> (totalAssets: Double, liabilities: Double, netAssets: Double, debtRatio: Double, liquidAssets: Double, lastModified: Date?, liabilitiesDiff: Double, netAssetsDiff: Double, chartData: [ChartDataForAssetCategory]) {
        let items = DataQuery.query(context, as: Asset.self, size: -1)
        let (totalAssets, liabilities, netAssets, debtRatio, lastModified) = summary(items)
        let liquidAssets = sumByCategory(items, AssetCategory.liquidAssets)
        
        let lateLastMonth = Date.now.plusMonth(-1).endOfMonth()
        let liabilitiesOfLastMonth = amountAt(context, category: .liabilities, date: lateLastMonth).amount
        let netAssetsOfLastMonth = amountAt(context, category: nil, date: lateLastMonth).amount
        
        var chartData = AssetCategory.allCases.map { category in
            let value = items.filter { $0.category == category }
            let amount = value.reduce(0, {$0 + $1.amount})
            
            let lastMonthAmount = value.map{ amountAt(context, assetId: $0.id, date: lateLastMonth).amount }
                .reduce(0, +)
            
            return ChartDataForAssetCategory(name: category.name, isAsset: category.isAsset, amount: amount, lastMonthAmount: lastMonthAmount, backgroundColor: Color(hex: category.backgroundColor))
        }
        chartData.append(ChartDataForAssetCategory(name: "净增长", isAsset: true, amount: netAssets, lastMonthAmount: netAssetsOfLastMonth, backgroundColor: Color(hex: netAssetsColor).opacity(0.2)))

        return (totalAssets, liabilities, netAssets, debtRatio, liquidAssets, lastModified, abs(liabilities) - abs(liabilitiesOfLastMonth), netAssets - netAssetsOfLastMonth, chartData)
    }
    
    /// 查找有数据的年份
    static func fetchYearsWithData(_ context: ModelContext) -> [Int] {
        var cursorYear = Date.distantFuture
        var years = [Int]()
        while let cursor = DataQuery.queryOne(context, as: AssetChangeLog.self, predicate: AssetChangeLog.predicateFor(.filterByDateLessThan(date: cursorYear))) {
            years.append(cursor.date.year)
            cursorYear = cursor.date.plusYear(-1).endOfYear()
        }
        return years
    }
    
    /// 资产月历数据
    static func aggregateForMonthlyByCategory(_ context: ModelContext, _ category: AssetCategory? = nil, _ selectedYear: Int) -> ChartDataForAssetMonthly {
        let name = category?.name ?? netAssetsName
        let color = Color(hex: category?.textColor ?? netAssetsColor)
        let isAsset = category?.isAsset ?? true
        
        // 选中年份的最后修改时间
        var lastModified: Date? = nil
        
        // 选中年份结束时的总资产
        var latestAmount = 0.0
        
        let maxMonth = selectedYear == Date.now.year ? Date.now.month : 12
        
        var datas = [MonthlyItem]()
        for month in 1...12 {
            let lastMonthAmount = month > 1 ? latestAmount : amountAt(context, category: category, date: Date(year: selectedYear, month: month).plusMonth(-1).endOfMonth()).amount

            var amount = 0.0
            if month <= maxMonth {
                let amtAndDate = amountAt(context, category: category, date: Date(year: selectedYear, month: month).endOfMonth())
                amount = amtAndDate.amount
                latestAmount = amount
                
                if let modifiedTime = amtAndDate.modifiedTime, (lastModified ?? .distantPast) < modifiedTime {
                    lastModified = modifiedTime
                }
            }
            
            datas.append(MonthlyItem(date: Date(year: selectedYear, month: month), amount: amount, lastMonthAmount: lastMonthAmount))
        }
        
        return ChartDataForAssetMonthly(name: name, isAsset: isAsset, latestAmount: latestAmount, lastModified: lastModified, data: datas, color: color)
    }
    
    static func aggregateForMonthlyChanges(_ context: ModelContext, _ selectedYear: Int, name: String = "月度净增长") -> ChartDataForAssetMonthly {
        // 选中年份结束时的总资产
        var latestAmount = 0.0
        
        // 选中年份的最后修改时间
        var lastModified: Date? = nil
        
        let maxMonth = selectedYear == Date.now.year ? Date.now.month : 12
        
        var datas = [MonthlyItem]()
        for month in 1...12 {
            let lastMonthAmount = month > 1 ? latestAmount : amountAt(context, category: nil, date: Date(year: selectedYear, month: month).plusMonth(-1).endOfMonth()).amount

            var amount = 0.0
            if month <= maxMonth {
                let amtAndDate = amountAt(context, category: nil, date: Date(year: selectedYear, month: month).endOfMonth())
                amount = amtAndDate.amount
                latestAmount = amount
                
                if let modifiedTime = amtAndDate.modifiedTime, (lastModified ?? .distantPast) < modifiedTime {
                    lastModified = modifiedTime
                }
            }
            
            if month == 12 {
                print(amount, lastMonthAmount)
            }
            
            /// 净增长 = 当前 - 上月
            datas.append(MonthlyItem(date: Date(year: selectedYear, month: month), amount: amount - lastMonthAmount, lastMonthAmount: 0))
        }
        
        return ChartDataForAssetMonthly(type: .growth, name: name, isAsset: true, latestAmount: 0, lastModified: lastModified, data: datas, color: Color.green.opacity(0.75))
    }
    
    /// 逆序回溯每一次改变
    static func amountAtChangePoints(_ context: ModelContext, startDate: Date = .distantPast) -> [StackedAreaData] {
        var changePoints = [StackedAreaData]()
        var cursorDate = Date.now
        
        /// 从当前时间开始回溯, 一天中存在多次改动时使用最新
        let values: [(category: AssetCategory, amount: Double)] = AssetCategory.allCases.map { (category: $0, amount: amountAt(context, category: $0, date: cursorDate).amount) }
        changePoints.append(StackedAreaData(date: cursorDate, values: values))
        cursorDate = cursorDate.plusDay(-1).endOfDay()
        
        while true {
            let cursor = amountAt(context, date: cursorDate)
            if let modifiedTime = cursor.modifiedTime {
                let values: [(category: AssetCategory, amount: Double)] = AssetCategory.allCases.map { (category: $0, amount: amountAt(context, category: $0, date: modifiedTime).amount) }
                
                changePoints.append(StackedAreaData(date: modifiedTime, values: values))
                cursorDate = modifiedTime.plusDay(-1).endOfDay()
                
                if cursorDate < startDate {
                    break
                }
            } else {
                break
            }
        }

        return changePoints
    }
}
