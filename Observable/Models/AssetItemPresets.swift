//
//  AssetItemPresets.swift
//  Observable
//
//  Created by whoog on 2024/11/4.
//

import Foundation

public enum AssetItemPresets: String, Codable, CaseIterable, Identifiable, Sendable {
    
    case bankAccount = "银行卡"
    case alipay = "支付宝"
    case wechat = "微信"
    
    case realEstate = "房产(自住)"
    case realEstateInvest = "房产(投资)"
    case vehicle = "车辆"
    
    case bankInvestment = "银行理财"
    case fund = "基金"
    
    case loanToOthers = "借给他人的钱"
    
    case mortgage = "房贷"
    case carLoan = "车贷"
    case creditCard = "信用卡"
    case jdLoan = "京东白条"
    case alipayLoan = "花呗"
    case onlineLoan = "网贷"
    case personalLoan = "个人贷款"
    
    public var id: String { rawValue }
    var name: String { rawValue }

    static let moreAssetIcon = "asset-type-more"
    
    var category: AssetCategory {
        switch self {
        case .bankAccount, .alipay, .wechat:
            return .liquidAssets
        case .realEstate, .realEstateInvest, .vehicle:
            return .fixedAssets
        case .bankInvestment, .fund:
            return .investments
        case .loanToOthers:
            return .receivables
        case .mortgage, .carLoan, .creditCard, .jdLoan, .alipayLoan, .onlineLoan, .personalLoan:
            return .liabilities
        }
    }
    
    var icon: String? {
        switch self {
        case .bankAccount: "asset-type-bankAccount"
        case .alipay: "asset-type-alipay"
        case .wechat: "asset-type-wechat"
            
        case .realEstate: "asset-type-realEstate"
        case .realEstateInvest: "asset-type-realEstateInvest"
        case .vehicle: "asset-type-vehicle"
            
        case .bankInvestment: "asset-type-bankInvestment"
        case .fund: "asset-type-fund"
            
        case .loanToOthers: "asset-type-loanToOthers"
            
        case .mortgage: "asset-type-mortgage"
        case .carLoan: "asset-type-carLoan"
        case .creditCard: "asset-type-creditCard"
        case .jdLoan: "asset-type-jdLoan"
        case .alipayLoan: "asset-type-alipayLoan"
        case .onlineLoan: "asset-type-onlineLoan"
        case .personalLoan: "asset-type-personalLoan"
        }
    }
    
    var describe: String {
        switch self {
        case .bankAccount: "银行活期，随时可用的流动资金"
        case .alipay: "支付宝账户可用余额"
        case .wechat: "微信账户可用余额"
            
        case .realEstate: "自住房产，低流动性实物资产"
        case .realEstateInvest: "投资性房产，具备增值潜力的固定资产"
        case .vehicle: "车辆，作为个人交通工具的固定资产"
            
        case .bankInvestment: "银行理财产品，低风险的增值投资"
        case .fund: "基金投资，具备较高收益与风险的金融产品"
            
        case .loanToOthers: "借给他人的款项，待回收的应收资金"
            
        case .mortgage: "房产贷款，分期偿还的负债"
        case .carLoan: "汽车贷款，分期偿还的车辆负债"
        case .creditCard: "信用卡欠款，短期消费负债"
        default: ""
        }
    }
}
