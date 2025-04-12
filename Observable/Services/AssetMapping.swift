//
//  AssetMapping.swift
//  Observable
//
//  Created by whoog on 2024/11/14.
//

import Foundation

extension Asset {
    
    public static func mapping(_ items: [Asset], _ config: SankeyConfig, compressed: Bool = false) -> (nodes: [SankeyNode], links: [NodeLink]) {
        var items_ = items
        if compressed {
            items_ = [Asset]()
            AssetCategory.allCases.forEach { category in
                let grouped = items.filter { $0.category == category }
                
                if !grouped.isEmpty {
                    items_.append(Asset(category: category, name: "\(grouped.count)项\(category.name)", amount: grouped.reduce(0, { $0 + $1.amount })))
                }
            }
        }
        
        return (buildNodes(items_, config), buildLinks(items_, config))
    }
    
    private static func buildNodes(_ items: [Asset], _ config: SankeyConfig) -> [SankeyNode] {
        var nodes = [SankeyNode]()
        nodes.append(SankeyNode(name: config.totalAssetsText, color: AssetCategory.liabilities.sankeyColor, tag: 1))
        
        AssetCategory.allCases.sorted(by: \.sankeyPriority).forEach { category in
            let matched = items.filter { $0.category == category }
                .map { SankeyNode(name: $0.name, color: category.sankeyChildrenColor, tag: category.isLiability ? 3 : nil) }
            
            if matched.isEmpty {
                return
            }
            
            if category.isAsset {
                nodes.append(SankeyNode(name: category.name, color: category.sankeyColor, tag: nil))
            }
            
            nodes += matched
        }
        
        nodes.append(SankeyNode(name: config.netAssetsText, color: config.netAssetsNodeColor, tag: 2))
        return nodes
    }
    
    private static func buildLinks(_ items: [Asset], _ config: SankeyConfig) -> [NodeLink] {
        var links = [NodeLink]()
        
        links += items
            .filter {  $0.category.isLiability }
            .map { item in
                NodeLink(source: item.name, target: config.totalAssetsText, value: abs(item.amount)) // 图表负债也传正数
            }
        
        let assets = items.filter { $0.category.isAsset }
        let assetGroups: [AssetCategory:[Asset]]  = Dictionary(grouping: assets, by: \.category)
        
        assetGroups.forEach { (key: AssetCategory, value: [Asset]) in
            let total = value.reduce(0, { $0 + $1.amount })
            
            links.append(NodeLink(source: config.totalAssetsText, target: key.name, value: total))
            links += value.map { item in
                NodeLink(source: item.category.name, target: item.name, value: item.amount)
            }
        }
        return links
    }
}
