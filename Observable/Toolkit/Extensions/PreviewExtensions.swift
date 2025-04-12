//
//  PreviewExtensions.swift
//  Observable
//
//  Created by whoog on 2024/11/11.
//

import SwiftUI
import SwiftData

extension View {
    func preview(_ consumer: (ModelContext) -> Void) -> some View {
        let dataProvider = DataProvider()
        consumer(dataProvider.previewContainer.mainContext)
        return self.modelContainer(dataProvider.previewContainer)
    }
    
    func preview(_ category: AssetCategory? = nil, months: Int = 2, random: Bool = false) -> some View {
        let dataProvider = DataProvider()
        let context = dataProvider.previewContainer.mainContext
        generatePreviewData(context, category, months: months, random: random)
        
        return self.modelContainer(dataProvider.previewContainer)
    }
}
