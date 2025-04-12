//
//  ObservableApp.swift
//  Observable
//
//  Created by whoog on 2024/11/1.
//

import SwiftUI
import SwiftData

@main
struct ObservableApp: App {
    let dataProvider = DataProvider.shared
    
    init() {
        dataProvider.initializeBasicData()
    }
    
    var body: some Scene {
        WindowGroup {
            AssetOverviewView()
        }
        .modelContainer(dataProvider.sharedContainer)
    }
}
