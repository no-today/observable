//
//  AssetEditingView.swift
//  Observable
//
//  Created by whoog on 2024/8/26.
//

import SwiftUI

enum SheetType: Identifiable {
    case moreItems, addAsset, updateAmount
    
    var id: Int { hashValue }
}

struct AssetRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var activeSheet: SheetType?
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    @State private var selectedCategory: AssetCategory = .liquidAssets
    @State private var selectedDefinition: AssetItemPresets? = nil
    @State private var selectedAsset: Asset? = nil
    
    @State private var showFileExporter = false
    @State private var transferable: AssetTransferable?
    
    private func onSheet(_ sheet: SheetType?) {
        self.activeSheet = sheet
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                header()
                
                ScrollViewReader { scrollViewProxy in
                    CategoriesView(scrollViewProxy: $scrollViewProxy, selectedCategory: $selectedCategory)
                        .onAppear {  self.scrollViewProxy = scrollViewProxy }
                    ItemsView(scrollViewProxy: $scrollViewProxy, selectedCategory: $selectedCategory, activeSheet: $activeSheet, selectedDefinition: $selectedDefinition, selectedAsset: $selectedAsset)
                }
                Spacer()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .moreItems:
                    PresetItems(activeSheet: $activeSheet, selectedCategory: $selectedCategory, selectedDefinition: $selectedDefinition)
                        .presentationDetents([.medium])
                        .presentationBackgroundInteraction(.automatic)
                case .addAsset:
                    assetDetailView(.addAsset)
                case .updateAmount:
                    assetDetailView(.updateAmount)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(Color(hex: "252525"))
                })
            }
        }
    }
    
    @ViewBuilder
    private func assetDetailView(_ mode: AssetDetailView.ViewMode) -> some View {
        AssetDetailView(mode: mode, category: $selectedCategory, asset: $selectedAsset, definition: $selectedDefinition, onSheet: onSheet)
            .presentationDetents([.large])
            .presentationBackgroundInteraction(.automatic)
    }
    
    @ViewBuilder
    private func header() -> some View {
        // Header
        HStack(spacing: 25) {
            Text("资产记账").font(.title.bold())
            
            Spacer()
            
            Button {
                exportData()
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .fileExporter(isPresented: $showFileExporter, item: transferable, contentTypes: [.json], defaultFilename: "assets") { result in
                switch result {
                case .success(_):
                    print("Export success")
                case .failure(let err):
                    print("Export failure: \(err.localizedDescription)")
                }
            }
            
            NavigationLink {
                SankeyFullScreenView()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 7)
    }
    
    private func exportData() {
        Task.detached(priority: .background) {
            // 在主 actor 上安全地访问 `modelContext`
            let data = await MainActor.run {
                DataQuery.query(modelContext, as: Asset.self)
            }
            let transferable = AssetTransferable(assets: data)
            
            // UI Must be on Main Thread
            await MainActor.run {
                self.transferable = transferable
                showFileExporter = true
            }
        }
    }
}

struct CategoriesView: View {
    @Binding var scrollViewProxy: ScrollViewProxy?
    @Binding var selectedCategory: AssetCategory
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(AssetCategory.allCases.indices, id: \.self) { index in
                        let category = AssetCategory.allCases[index]
                        
                        AggregateView(for: Asset.self, filter: Asset.predicateFor(.filterByCategory(category: category)), mapping: { $0.reduce(0) { $0 + $1.amount } }) { totalAmount in
                            ZStack {
                                VStack(spacing: 10) {
                                    Text(category.name).font(.headline)
                                    
                                    if totalAmount == 0 {
                                        Text("待填写").font(.caption2).foregroundStyle(Color(hex: "BDBDBD"))
                                    } else {
                                        Text("\(totalAmount.formatted())元").font(.caption).foregroundStyle(.black)
                                    }
                                }
                                .frame(width: max(geo.size.width / 3 - 19, 1), height: 75)
                                .background(Color(hex: category.backgroundColor).opacity(selectedCategory == category ? 0.5 : 0.75))
                                .foregroundColor(Color(hex: category.textColor))
                                .cornerRadius(15)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
                                        .strokeBorder(selectedCategory == category ? Color(hex: category.textColor).opacity(0.7) : .clear, lineWidth: 1)
                                }
                                .id(category)
                                .onTapGesture {
                                    withAnimation {
                                        selectedCategory = category
                                        scrollViewProxy?.scrollTo(category, anchor: .center)
                                    }
                                }
                            }
                        }
                        
                        // 插入间隔图标
                        if index < AssetCategory.allCases.count - 1 {
                            Image(systemName: "chevron.right")
                                .frame(width: 1)
                                .font(.caption2)
                                .foregroundColor(Color(hex: "C1C0C2"))
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            
        }
        .frame(height: 90)
    }
}

struct Header: View {
    let title: String
    let icon: String?
    let onClose: () -> Void
    let onAction: () -> Void
    
    var body: some View {
        HStack {
            // 左上角的关闭按钮
            Button(action: { onClose() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray.opacity(0.5))
            }
            Spacer()
            
            // 中间的标题
            Text("\(title)")
                .font(.headline)
            
            Spacer()
            
            // 右上角的设置按钮
            Button(action: { onAction() }) {
                Image(systemName: icon ?? "")
                    .foregroundColor(Color.red)
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 10)
    }
}

struct ItemsView: View {
    @Binding var scrollViewProxy: ScrollViewProxy?
    @Binding var selectedCategory: AssetCategory
    @Binding var activeSheet: SheetType?
    @Binding var selectedDefinition: AssetItemPresets?
    @Binding var selectedAsset: Asset?
    
    var body: some View {
        TabView(selection: $selectedCategory) {
            ForEach(AssetCategory.allCases) { category in
                ScrollView(showsIndicators: false) {
                    Color.clear.frame(height: 8)
                    QueryView(for: Asset.self, filter: Asset.predicateFor(.filterByCategory(category: category)), sort: [.init(\.createdDate, order: .forward)]) { items in
                        /// 视图展示逻辑：优先展示以填写的, 如果一个都没有填写, 那么展示全部定义
                        if !items.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("我").font(.title3.bold()).foregroundStyle(Color(hex: "5F518D"))
                                    Spacer()
                                }
                                
                                ForEach(items) { row(nil, $0) }
                            }
                            .padding(.top)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 10)
                            .background(Color(hex: "FAFAFA"))
                            .cornerRadius(15)
                            
                            Color.clear.frame(height: 10)
                            
                            moreItem(category)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(category.children()) { row($0) }
                                moreItem(category)
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .tag(category)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onChange(of: selectedCategory) {
            withAnimation {
                scrollViewProxy?.scrollTo(selectedCategory, anchor: .center)
            }
        }
    }
    
    @ViewBuilder
    fileprivate func row(_ def: AssetItemPresets?, _ asset: Asset? = nil) -> some View {
        let isDef = asset == nil
        
        HStack(spacing: 8) {
            if asset == nil {
                Image(def?.icon ?? AssetItemPresets.moreAssetIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            }
            
            Text(def?.name ?? asset?.name ?? "").font(.subheadline)
            
            Spacer()
            
            if let asset {
                VStack(alignment: .trailing) {
                    Text("¥ \(asset.amount.formatted())").font(.callout)
                    
                    Text(asset.lastModified.formatDateToCustomString()).font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "plus")
                    .frame(width: 10)
                    .font(.body.bold())
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, isDef ? 20 : 15)
        .padding(.horizontal, 20)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.gray)
                .opacity(isDef ? 1 : 0)
        )
        .cornerRadius(15)
        .onTapGesture {
            withAnimation {
                selectedDefinition = def
                selectedAsset = asset
                activeSheet = isDef ? .addAsset : .updateAmount
            }
        }
    }
    
    @ViewBuilder
    private func moreItem(_ category: AssetCategory) -> some View {
        HStack(spacing: 10) {
            Image(AssetItemPresets.moreAssetIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            Text("更多\(category.name)").font(.subheadline)
            
            Spacer()
            
            Image(systemName: "plus")
                .frame(width: 10)
                .font(.body.bold())
                .foregroundColor(.gray)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.gray)
        )
        .cornerRadius(15)
        .onTapGesture {
            selectedAsset = nil
            activeSheet = .moreItems
        }
    }
}

struct PresetItems: View {
    @Binding var activeSheet: SheetType?
    @Binding var selectedCategory: AssetCategory
    @Binding var selectedDefinition: AssetItemPresets?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if selectedCategory.describe != "" {
                    HStack {
                        Text(selectedCategory.describe)
                        Spacer()
                    }
                    .padding(15)
                    .foregroundStyle(Color(hex: "67607C"))
                    .font(.footnote)
                    .background(Color(hex: "F3EAED").opacity(0.7))
                    .cornerRadius(15)
                }
                
                // Hack code, 不想要 title 的滚动动画
                Color.clear.frame(height: 3).background()
                
                ScrollView(showsIndicators: false) {
                    VStack {
                        QueryView(for: Asset.self, filter: Asset.predicateFor(.filterByCategory(category: selectedCategory))) { items in
                            let exists = items.map(\.name)
                            let unused = selectedCategory.children().filter({ !exists.contains($0.name) })
                            
                            ForEach(unused.indices, id: \.self) { index in
                                let item = unused[index]
                                row(item.category, item)
                            }
                            
                            row(selectedCategory)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .cornerRadius(15)
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle("更多\(selectedCategory.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        withAnimation {
                            activeSheet = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(Color(hex: "BFBFBF"))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func row(_ category: AssetCategory, _ def: AssetItemPresets? = nil) -> some View {
        HStack(spacing: 8) {
            Image(def?.icon ?? AssetItemPresets.moreAssetIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            Text(def?.name ?? "自定义\(category.name)").font(.subheadline)
            
            Spacer()
            
            Image(systemName: "plus")
                .frame(width: 10)
                .font(.body.bold())
                .foregroundColor(.gray)
        }
        .padding(.vertical)
        .padding(.horizontal, 5)
        .contentShape(Rectangle()) // 扩大点击区域
        .onTapGesture {
            withAnimation {
                selectedDefinition = def
                activeSheet = .addAsset
            }
        }
    }
}

#Preview {
    AssetRegistrationView()
        .preview()
}
