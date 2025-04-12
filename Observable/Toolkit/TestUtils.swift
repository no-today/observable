//
//  TestUtils.swift
//  Observable
//
//  Created by whoog on 2024/11/20.
//

import Foundation
import SwiftData

func generatePreviewData(_ context: ModelContext, _ category: AssetCategory? = nil, months: Int = 2, random: Bool = false) {
    mockDataAssetItems
        .filter { category == nil || $0.category == category }
        .forEach { asset in
            let assetId = AssetManager.insertAsset(context, category: asset.category, name: asset.name, amount: asset.amount, createdDate: asset.createdDate)
            
            for i in 1..<months {
                AssetManager.updateAmount(context,
                                          assetId: assetId,
                                          amount:  random ? Double(Int(asset.amount * Double.random(in: 0.1...2))) : Double(asset.amount / Double(i + 1)),
                                          date: .now.plusMonth(-(i)))
            }
        }
}
