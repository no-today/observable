//
//  PersistentHelper.swift
//  Insights
//
//  Created by no-today on 2024/5/23.
//

import SwiftData
import SwiftUI

struct PaginatedView<Model: PersistentModel, Content: View>: View {
    @Environment(\.modelContext) private var context

    @Binding var triggerReload: Bool
    @Binding var paginationOffset: Int?
    var itemsPerPage: Int
    @State var isLast: Bool = false

    /// View Properties
    @State private var items: [Model] = []
    
    @ViewBuilder var content: ([Model], Bool) -> Content
    

    var type: Model.Type
    var filter: Predicate<Model>?
    var sort: [SortDescriptor<Model>]

    init(for type: Model.Type,
         filter: Predicate<Model>? = nil,
         sort: [SortDescriptor<Model>] = [],
         paginationOffset: Binding<Int?>,
         itemsPerPage: Int = 5,
         triggerReload: Binding<Bool>,
         @ViewBuilder content: @escaping ([Model], Bool) -> Content) {
        self.type = type
        self.filter = filter
        self.sort = sort
        self._paginationOffset = paginationOffset
        self.itemsPerPage = itemsPerPage
        self._triggerReload = triggerReload
        self.content = content
    }
        
    fileprivate func fetchData(_ newValue: Int, reload: Bool = false) {
        do {
            var descriptor = FetchDescriptor<Model>(predicate: filter, sortBy: sort)
            /// Total Count
            let totalCount = try context.fetchCount(descriptor)
            
            if reload {
                descriptor.fetchOffset = 0
                descriptor.fetchLimit = items.count
                items = []
            } else {
                /// Limitting Page Offset
                descriptor.fetchOffset = min(min(totalCount, newValue), items.count)
                /// Setting Up Descriptor for Pagination
                descriptor.fetchLimit = itemsPerPage
            }
            
            /// Fetching New Data
            let newData = try context.fetch(descriptor)
            items.append(contentsOf: newData)
            
            /// Last
            if totalCount == items.count {
                isLast = true
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        content(items, isLast)
            .onChange(of: triggerReload) {
                fetchData(0, reload: true)
            }
            .onChange(of: paginationOffset, initial: false) { oldValue, newValue in
                guard let newValue else { return }
                fetchData(newValue)
            }
    }
}

/// Swift Data @Query: https://ihor.pro/implementing-a-swiftdata-query-view-as-the-most-convenient-way-to-fetch-data-in-swiftui-f69d59348783
struct QueryView<Model: PersistentModel, Content: View>: View {

    @Query private var items: [Model]
    private var content: ([Model]) -> (Content)
    
    init(for type: Model.Type,
         filter: Predicate<Model>? = nil,
         sort: [SortDescriptor<Model>] = [],
         page: Int? = nil,
         size: Int? = nil,
         @ViewBuilder content: @escaping ([Model]) -> Content) {
        
        var descriptor = FetchDescriptor<Model>(predicate: filter, sortBy: sort)
        if let page, let size {
            descriptor.fetchOffset = (page - 1) * size
            descriptor.fetchLimit = size
        }
        
        _items = Query(descriptor)
        self.content = content
    }
    
    var body: some View {
        content(items)
    }
}

struct GroupQueryView<Content: View, Model: PersistentModel, Key: Hashable & Comparable>: View {

    @Query private var items: [Model]
    
    private var groupBy: (Model) -> Key
    private var content: ([QueryDataGroup<Key, Model>]) -> (Content)
    
    init(for type: Model.Type,
         groupBy: @escaping ((Model) -> Key),
         filter: Predicate<Model>? = nil,
         sort: [SortDescriptor<Model>] = [],
         @ViewBuilder content: @escaping ([QueryDataGroup<Key, Model>]) -> Content) {
        
        _items = Query(filter: filter, sort: sort)
        self.groupBy = groupBy
        self.content = content
    }
    
    var body: some View {
        content(groups(items))
    }
    
    private func groups(_ items: [Model]) -> [QueryDataGroup<Key, Model>] {
        let data: [Key:[Model]] = Dictionary(grouping: items, by: groupBy)
        let groups: [QueryDataGroup] = data.keys.reduce([QueryDataGroup]()) { partialResult, key in
            partialResult + [.init(key: key, items: data[key] ?? [])]
        }
        
        return groups
    }
}

struct QueryDataGroup<Key: Hashable & Comparable, Model: PersistentModel>: Identifiable, Comparable {
    public var id = UUID()
    public var key: Key
    public var items: [Model]
    
    static func < (lhs: QueryDataGroup<Key, Model>, rhs: QueryDataGroup<Key, Model>) -> Bool {
        lhs.key < rhs.key
    }
}

/// https://gist.github.com/bigmountainstudio/cc6beba0ef18284696e97e59d8eb8cc0
struct AggregateView<Model: PersistentModel, Content: View, T>: View {

    @Query private var items: [Model]
    private var content: (T) -> (Content)
    private var mapping: ([Model]) -> T

    init(for type: Model.Type,
         filter: Predicate<Model>? = nil,
         page: Int? = nil,
         size: Int? = nil,
         mapping: @escaping ([Model]) -> T,
         @ViewBuilder content: @escaping (T) -> Content) {
        
        var descriptor = FetchDescriptor<Model>(predicate: filter)
        if let page, let size {
            descriptor.fetchOffset = (page - 1) * size
            descriptor.fetchLimit = size
        }
        
        _items = Query(descriptor)
        self.mapping = mapping
        self.content = content
    }
    
    var body: some View {
        content(mapping(items))
    }
}
