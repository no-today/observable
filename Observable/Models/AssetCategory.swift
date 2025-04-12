//
//  AssetCategory.swift
//  Observable
//
//  Created by whoog on 2024/9/5.
//

import Foundation

public enum AssetCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case liquidAssets
    case investments
    case receivables
    case fixedAssets
    case liabilities
    
    public var id: String { rawValue }
    
    var isLiability: Bool { self == .liabilities }
    var isAsset: Bool { !isLiability }
    
    func children() -> [AssetItemPresets] {
        AssetItemPresets.allCases.filter( { $0.category == self } )
    }
    
    var name: String {
        switch self {
        case .liquidAssets: "现金流"
        case .investments: "投资理财"
        case .receivables: "应收款"
        case .fixedAssets: "固定资产"
        case .liabilities: "负债"
        }
    }
    
    var describe: String {
        switch self {
        case .liquidAssets: "可随用随取、即时变现的钱"
        case .investments: "投资于金融产品，追求保值增值的钱"
        case .receivables: "应收未收的款项，如借给他人的钱，为他人垫付的资金"
        case .fixedAssets: "用于投资或自用的、流动性低的实物类资产"
        case .liabilities: ""
        }
    }
    
    var textColor: String {
        switch self {
        case .liquidAssets: "A06035"
        case .fixedAssets: "5C7E8E"
        case .investments: "655F7C"
        case .receivables: "596583"
        case .liabilities: "7F7E86"
        }
    }
    
    var backgroundColor: String {
        switch self {
        case .liquidAssets: "FBEBE4"
        case .fixedAssets: "E8F4FA"
        case .investments: "EFEBF6"
        case .receivables: "E9EDF6"
        case .liabilities: "F1F1F3"
        }
    }
    
    /// Node order in Sankey diagram
    var sankeyPriority: Int {
        switch self {
        case .liabilities: 1
        case .liquidAssets: 2
        case .investments: 3
        case .fixedAssets: 4
        case .receivables: 5
        }
    }
    
    /// Cagetory node colors in Sankey diagrams
    var sankeyColor: String {
        switch self {
        case .liabilities: "#9191BE" // 实际上是总资产的颜色, 负债是用的 config.totalDebtNodeColor
        case .liquidAssets: "#CD8A68"
        case .investments: "#C4BBD6"
        case .fixedAssets: "#82A9B7"
        case .receivables: "#8694AE"
        }
    }
    
    /// Item node colors in Sankey diagrams
    var sankeyChildrenColor: String {
        switch self {
        case .liabilities: "#A6A6B0"
        case .liquidAssets: "#CD8A68"
        case .investments: "#C4BBD6"
        case .fixedAssets: "#82A9B7"
        case .receivables: "#8694AE"
        }
    }
}
