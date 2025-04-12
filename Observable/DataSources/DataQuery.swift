//
//  AssetQuery.swift
//  Observable
//
//  Created by whoog on 2024/11/14.
//

import Foundation
import SwiftData

struct PageInfo<Entity> {
    var page: Int
    var size: Int
    
    var list: [Entity]
    var totals: Int
    
    var totalPage: Int { totals % size == 0 ? totals / size : totals / size + 1 }
    var hasNext: Bool { page < totalPage }
    var isLast: Bool { !hasNext }
}

struct DataQuery {
    
    static func query<Entity: PersistentModel>(_ context: ModelContext, as as_: Entity.Type, predicate: Predicate<Entity>? = nil, sortBy: [SortDescriptor<Entity>] = [], page: Int = 1, size: Int = 0) -> [Entity] {
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)
        
        if size > 0 {
            descriptor.fetchOffset = max(0, (page - 1) * size)
            descriptor.fetchLimit = size
        }
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    static func queryOne<Entity: PersistentModel>(_ context: ModelContext, as as_: Entity.Type, predicate: Predicate<Entity>? = nil, sortBy: [SortDescriptor<Entity>] = []) -> Entity? {
        query(context, as: as_, predicate: predicate, sortBy: sortBy, size: 1).first
    }
    
    static func page<Entity: PersistentModel>(_ context: ModelContext, as as_: Entity.Type, predicate: Predicate<Entity>? = nil, sortBy: [SortDescriptor<Entity>] = [], page: Int = 1, size: Int = 100) -> PageInfo<Entity> {
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)
        let totals = try? context.fetchCount(descriptor)
        
        descriptor.fetchOffset = max(max(0, (page - 1) * size), totals ?? 0)
        descriptor.fetchLimit = size
        
        let list = try? context.fetch(descriptor)
        return PageInfo(page: page, size: size, list: list ?? [], totals: totals ?? 0)
    }
}
