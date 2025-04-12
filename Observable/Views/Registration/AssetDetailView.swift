//
//  AssetDetailView.swift
//  Observable
//
//  Created by whoog on 2024/9/9.
//

import SwiftUI

struct AssetDetailView: View {
    
    enum ViewMode {
        case addAsset, updateAmount, modifyAsset, changeLog
    }
    
    enum SecondSheet: Identifiable {
        case modifyAsset, changeLog
        
        var id: Int { hashValue }
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
        
    @State private var isFirstEntry = true
    @State private var showDatePicker = false
    @State private var showDeleteAlert = false
    @State private var secondSheet: SecondSheet? = nil
    @State private var selectedAssetLog: AssetChangeLog? = nil
        
    let mode: ViewMode
    let onSheet: (SheetType?) -> Void
    
    @State var date: Date = .now
    @State var name: String = ""
    @State var amount: String = ""
    @State var describe: String = ""
    
    @Binding var category: AssetCategory
    @Binding var asset: Asset?
    @Binding var definition: AssetItemPresets?
    @Binding var assetLog: AssetChangeLog?
    
    @State var logsTriggerReload: Bool = false
    
    var viewTitle: String {
        switch mode {
        case .addAsset: definition?.name ?? "自定义\(category.name)"
        case .updateAmount: asset?.name ?? ""
        case .modifyAsset: "编辑资产"
        case .changeLog: "资产记录"
        }
    }
    
    var viewSubTitle: String {
        if mode == .changeLog {
            assetLog?.date.formatted("M月dd日") ?? ""
        } else {
            ""
        }
    }
    
    init(mode: ViewMode, category: Binding<AssetCategory>, asset: Binding<Asset?> = .constant(nil), definition: Binding<AssetItemPresets?> = .constant(nil), assetLog: Binding<AssetChangeLog?> = .constant(nil), onSheet: @escaping (SheetType?) -> Void) {
        self.mode = mode
        self._category = category
        self._asset = asset
        self._definition = definition
        self._assetLog = assetLog
        self.onSheet = onSheet
    }
    
    func refreshUI() {
        switch mode {
        case .addAsset:
            if let definition = definition {
                name = definition.name
                describe = definition.describe
            }
        case .updateAmount:
            if let asset = asset {
                describe = AssetItemPresets(rawValue: asset.name)?.describe ?? ""
            }
        case .modifyAsset:
            if let asset = asset {
                name = asset.name
                date = asset.lastModified
            }
        case .changeLog:
            if let assetLog = assetLog {
                amount = assetLog.amount.formatted()
                date = assetLog.date
            }
        }
    }
    
    private var disabled: Bool {
        return switch mode {
        case .addAsset:
            name.isEmpty || amount.isEmpty
        case .updateAmount:
            amount.isEmpty
        case .modifyAsset:
            name.isEmpty
        case .changeLog:
            false
        }
    }
    
    // --------------------------
    
    private func save() {
        Task { @MainActor in
            if let asset = asset {
                AssetManager.updateAmount(modelContext, asset: asset, name: name, amount: Double(amount), date: date)
            } else {
                let _ = AssetManager.insertAsset(modelContext, category: category, name: name, amount: Double(amount) ?? 0, createdDate: date)
            }
        }
    }
    
    private func delete() {
        Task { @MainActor in
            if let asset = asset {
                AssetManager.deleteAsset(modelContext, asset: asset)
            }
        }
    }
    
    private func updateLog(callback: @escaping () -> Void = {}) {
        Task { @MainActor in
            if let assetLog = assetLog {
                AssetManager.updateLog(modelContext, changeLog: assetLog, amount: Double(amount), date: date)
                callback()
            }
        }
    }
    
    private func deleteLog(callback: @escaping () -> Void = {}) {
        Task { @MainActor in
            if let assetLog = assetLog {
                AssetManager.deleteLog(modelContext, changeLog: assetLog)
                callback()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                describeBox
                
                // Hack code, 不想要 title 的滚动动画
                Color.clear.frame(height: 10).background()
                
                ZStack {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            viewContent
                        }
                        .padding(.top)
                        .applyIgnoringSafeArea(.keyboard, edges: .bottom, mode != .modifyAsset)
                        .padding(.bottom, 150)
                    }
                    
                    actionButton
                        .buttonStyle(PlainButtonStyle()) // 去除透明效果
                }
            }
            .padding(.horizontal)
            .cornerRadius(15)
            .navigationTitle(viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .onAppear {
                refreshUI()
            }
            .gesture(
                DragGesture().onChanged { value in
                    if value.translation.height > 0 {
                        hideKeyboard()
                    }
                }
            )
            .onTapGesture {
                hideKeyboard()
                
                withAnimation {
                    showDatePicker = false
                }
            }
            .onChange(of: asset) {
                refreshUI()
            }
            .sheet(item: $secondSheet) { sheet in
                switch sheet {
                case .modifyAsset:
                    AssetDetailView(mode: .modifyAsset, category: $category, asset: $asset) { sheet in
                        secondSheet = nil
                        onSheet(sheet)
                    }
                case .changeLog:
                    AssetDetailView(mode: .changeLog, category: $category, asset: $asset, assetLog: $selectedAssetLog) { sheet in
                        secondSheet = nil
                        logsTriggerReload.toggle()
                    }
                    .presentationDetents([.medium])
                    .presentationBackgroundInteraction(.automatic)
                }
            }
        }
    }
    
    @ViewBuilder
    var viewContent: some View {
        switch mode {
        case .addAsset:
            nameField()
            amountField(lable: "最新金额")
        case .updateAmount:
            dateField()
            amountField()
            ChangeLogsView(selectedAssetLog: $selectedAssetLog, secondSheet: $secondSheet, asset: $asset, triggerReload: $logsTriggerReload)
        case .modifyAsset:
            nameField()
            deleteBotton(title: "确定要删除当前资产吗?", msg: "资产项目与历史更新记录将会全部清除") {
                withAnimation {
                    delete()
                    dismiss()
                    onSheet(nil)
                }
            }
        case .changeLog:
            dateField()
            amountField()
            deleteBotton(title: "删除", msg: "确定删除当前记录吗?") {
                withAnimation {
                    deleteLog { // 删除后再关闭 sheet
                        onSheet(nil)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var actionButton: some View {
        switch mode {
        case .addAsset:
            botton("完成添加")
        case .updateAmount:
            botton("更新")
        default:
            Color.clear
        }
    }
    
    /// https://swiftlogic.io/posts/toolbar-content-builder/
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if mode != .changeLog {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(Color(hex: "BFBFBF"))
                }
            }
        }
        
        ToolbarItem {
            switch mode {
            case .addAsset:
                Color.clear
            case .updateAmount:
                Button {
                    hideKeyboard()
                    withAnimation {
                        secondSheet = .modifyAsset
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.callout.bold())
                        .foregroundColor(Color(hex: "272727"))
                }
            case .modifyAsset:
                Button("保存") {
                    withAnimation {
                        save()
                        dismiss()
                    }
                }
                .disabled(disabled)
            case .changeLog:
                Button("保存") {
                    withAnimation {
                        updateLog {
                            onSheet(nil)
                            dismiss()
                        }
                    }
                }
                .disabled(disabled)
            }
        }
    }
    
    @ViewBuilder
    var describeBox: some View {
        Text(viewSubTitle)
            .font(.caption).foregroundStyle(.secondary)
        
        if describe != "" {
            HStack {
                Text(describe)
                Spacer()
            }
            .padding(15)
            .foregroundStyle(Color(hex: "67607C"))
            .font(.footnote)
            .background(Color(hex: "F3EAED").opacity(0.7))
            .cornerRadius(15)
        }
    }
    
    @ViewBuilder
    private func nameField() -> some View {
        VStack(alignment: .leading) {
            Text("名称")
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "545454"))
            
            HStack {
                let placeholder = asset?.name ?? "点击输入名称"
                TextField(placeholder, text: $name)
            }
            .padding()
            .background(Color(hex: "FAFAFA"))
            .cornerRadius(10)
        }
    }
    
    private var selectedDateFormatted: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "\(date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))(今天)"
        } else {
            return date.formatted(.dateTime.year(.twoDigits).month(.twoDigits).day(.twoDigits))
        }
    }
    
    @ViewBuilder
    private func dateField() -> some View {
        VStack(alignment: .leading) {
            Text("更新日期")
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "545454"))
            
            HStack {
                Button(action: { withAnimation { showDatePicker.toggle() } }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text(selectedDateFormatted)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(180)) // 旋转180度，形成倒三角形
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "828282"))
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(hex: "FAFAFA"))
            .cornerRadius(10)
        }
        .overlay(alignment: .leading) {
            ZStack {
                if showDatePicker {
                    DatePicker("", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.wheel)
                        .background(.white)
                        .cornerRadius(15)
                        .shadow(radius: 1)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .opacity(showDatePicker ? 1 : 0)
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)),
                                removal: .scale.combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.5))
                            )
                        )
                }
            }
            .padding(.horizontal)
            .offset(y: 145)
        }
        .zIndex(1)
    }
    
    @ViewBuilder
    private func amountField(lable: String = "资产金额") -> some View {
        VStack(alignment: .leading) {
            Text(lable)
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "545454"))
            
            HStack {
                let placeholder = asset.map { "上次记录: \($0.amount.formatted())" } ?? "点击输入金额"
                
                TextField(placeholder, text: $amount)
                    .font(.body)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
                    .onChange(of: amount) {
                        amount = formatInput(amount, category)
                    }
                
                Text("元")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(hex: "FAFAFA"))
            .cornerRadius(10)
        }
    }
    
    // 格式化输入，只允许数字和最多两位小数
    private func formatInput(_ value: String, _ category: AssetCategory) -> String {
        // 只保留数字
        var filtered = value.filter { "-?0123456789".contains($0) }
        
        if filtered == "0" || filtered == "-0" {
            return filtered.replacingOccurrences(of: "-", with: "")
        } else if category.isAsset {
            filtered = filtered.replacingOccurrences(of: "-", with: "")
        } else {
            if filtered.count > 0 && filtered.first == "-" {
                filtered = "-\(filtered.replacingOccurrences(of: "-", with: ""))"
            } else {
                filtered = "-\(filtered)"
            }
        }
        
        return filtered
    }
    
    @ViewBuilder
    private func botton(_ title: String) -> some View {
        VStack {
            Spacer()
            
            Button(action: {
                withAnimation {
                    save()
                    onSheet(nil)
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(hex: disabled ? "C8E8FF" : "23A2FF"))
                    
                    Text(title)
                        .font(.callout)
                        .foregroundStyle(.white)
                }
                .frame(height: 45)
            }
            .padding()
            .background(.white)
            .disabled(disabled)
        }
        .zIndex(1)
    }
    
    @ViewBuilder
    private func deleteBotton(title: String, msg: String, onDelete: @escaping () -> Void) -> some View {
        HStack {
            Button {
                withAnimation {
                    showDeleteAlert = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F5F5F5"))
                    
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color(hex: "818181").opacity(0.75), .clear)
                }
                .frame(width: 40, height: 40)
            }
            .alert(Text(title), isPresented: $showDeleteAlert, actions: {
                Button("删除", role: .destructive, action: onDelete)
                Button("取消", role: .cancel) {}
            }, message: {
                Text(msg)
            })
        }
        .padding(.top, 50)
    }
    
    struct ChangeLogsView: View {
        @Environment(\.modelContext) private var modelContext

        @Binding var selectedAssetLog: AssetChangeLog?
        @Binding var secondSheet: SecondSheet?
        @Binding var asset: Asset?

        @Binding var triggerReload: Bool
        @State var paginationOffset: Int? = nil
        @State var itemsPerPage: Int = 3
        
        var body: some View {
            VStack {
                HStack {
                    Text("资产记录")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "545454"))
            
                    Spacer()
                }
                
                if let asset = asset {
                    content(asset)
                }
            }
            .onAppear {
                if paginationOffset == nil { paginationOffset = 0 }
            }
        }
        
        @ViewBuilder
        func content(_ asset: Asset) -> some View {
            PaginatedView(for: AssetChangeLog.self, filter: AssetChangeLog.predicateFor(.filterByAssetId(assetId: asset.id)), sort: [SortDescriptor<AssetChangeLog>(\.date, order: .reverse)], paginationOffset: $paginationOffset, itemsPerPage: itemsPerPage, triggerReload: $triggerReload) { logs, isLast in
                ForEach(logs) { log in
                    HStack {
                        Text(log.date.formatDateToCustomString())
                            .foregroundColor(.secondary)
            
                        Spacer()
            
                        Text(Int(log.amount).formatted())
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(hex: "FAFAFA"))
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedAssetLog = log
            
                        withAnimation {
                            secondSheet = .changeLog
                        }
                    }
                    .customOnAppear(false) {
                        if let paginationOffset, logs.last == log {
                            self.paginationOffset = paginationOffset + itemsPerPage
                        }
                    }
                }
                
                Text(isLast ? "已加载全部" : "Loading...")
                    .font(.caption)
                    .padding()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// --------------------------

#Preview("AssetDetailView#Add") {
    AssetDetailView(mode: .addAsset, category: .constant(.liquidAssets), onSheet: { _ in}).preview()
}

#Preview("AssetDetailView#Amount") {
    AssetDetailView(mode: .updateAmount, category: .constant(.liquidAssets), onSheet: { _ in}).preview()
}

#Preview("AssetDetailView#Modify") {
    AssetDetailView(mode: .modifyAsset, category: .constant(.liquidAssets), onSheet: { _ in}).preview()
}

#Preview("AssetDetailView#Record") {
    AssetDetailView(mode: .changeLog, category: .constant(.liquidAssets), onSheet: { _ in}).preview()
}
