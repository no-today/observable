//
//  DataSource.swift
//  Observable
//
//  Created by whoog on 2024/11/6.
//

import Foundation
import SwiftData

final class DataProvider {
    
    public let sharedContainer: ModelContainer
    public let previewContainer: ModelContainer
    
    @MainActor
    public static let shared = DataProvider()
    
    @MainActor
    public init() {
        sharedContainer = {
            let schema = Schema(CurrentScheme.models)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
        
        previewContainer = {
            let schema = Schema(CurrentScheme.models)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
    }
    
    @MainActor
    public func initializeBasicData() {
        if let count = try? sharedContainer.mainContext.fetchCount(FetchDescriptor<Asset>()), count == 0 {
            generatePreviewData(sharedContainer.mainContext, months: 12 * 3, random: true)
        }
    }
}
