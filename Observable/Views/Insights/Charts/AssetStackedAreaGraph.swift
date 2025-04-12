//
//  StackedAreaChartView.swift
//  Observable
//
//  Created by whoog on 2024/11/28.
//

import SwiftUI
import Charts

/// https://datavizcatalogue.com/ZH/方法/堆叠式面积图.html
///
/// 堆叠式面积图 (Stacked Area Graph) 的原理与简单面积图相同，
/// 但它能同时显示多个数据系列，每一个系列的开始点是先前数据系列的结束点。
///
/// 整个图表代表所有数据的总和。堆叠式面积图使用区域面积来表示整数，因此不适用于负值。
/// 总的来说，它们适合用来比较同一间隔内多个变量的变化。
///
///  Y: 价值轴
///  X: 时间轴
///
/// Issue List:
///  使用 chartScrollableAxis 时，RuleMark 展示不正常 https://forums.developer.apple.com/forums/thread/737244
///
struct AssetStackedAreaGraph: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var data: [StackedAreaData] = []
    @State private var selectedDate: Date?
    @State private var ignoredCategories = Set<AssetCategory>()
    @State private var isOnlyNetAssets: Bool = false
    
    /// 图表视距, 单位为天。记录间隔天数大于该值时启用滚动
    @State private var viewingDistance: Int = .max
    
    private var startDate: Date { data.last?.date ?? .now }
    private var endDate: Date { data.first?.date  ?? .now }
    private var betweenDays: Int { Date.betweenDays(startDate, endDate) }
    private var scrollable: Bool { betweenDays > viewingDistance }
    
    func refreshUI() {
        Task {
            // TODO 加一个更新检查, 有更新才拉数据
            let data = AssetAggregateQuery.amountAtChangePoints(modelContext)
            
            await MainActor.run {
                self.data = data
            }
        }
    }
    
    /// 找到距离选中时间最近的改动时间点
    func findNearestDatePoint(to date: Date?) -> StackedAreaData? {
        guard let date else { return nil }
        return data.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
    
    var body: some View {
        VStack {
            Chart(data) { item in
                chartContent(item)
                
                if let matched = findNearestDatePoint(to: selectedDate) {
                    RuleMark(x: .value("Date", matched.date))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [5]))
                        .foregroundStyle(.gray.opacity(0.5))
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: scrollable ? .fit(to: .automatic) : .disabled)) { timePointSummary(matched) }
                }
            }
            .conditionScrollable(scrollable, .horizontal, length: dynamicDateAxisLength(), initialX: endDate.timeIntervalSince1970)
            .chartForegroundStyleScale(chartColorStyleMapping(isOnlyNetAssets))
            .chartXSelection(value: $selectedDate)
            .chartLegend(position: .top, alignment: .center, spacing: 0) { chartLegend }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 6, roundLowerBound: false, roundUpperBound: false)) { value in
                    if let value = value.as(Double.self) {
                        AxisValueLabel(multiLabelAlignment: .bottomTrailing) {
                            Text(value.formatToK())
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    }
                }
            }
            
            HStack {
                Text(startDate.formatted("yy年MM月dd日")).font(.caption).foregroundStyle(.gray)
                Spacer()
                Text(endDate.formatted("yy年MM月dd日")).font(.caption).foregroundStyle(.gray)
            }
            .padding(.top, 2)
            .padding(.leading, 15)
            
            viewModeSwitchPanel
        }
        .onAppear {
            refreshUI()
        }
    }
    
    @ChartContentBuilder
    fileprivate func chartContent(_ item: StackedAreaData) -> some ChartContent {
        if isOnlyNetAssets {
            LineMark(
                x: .value("Date", item.date),
                y: .value("Amount", max(0, item.netAssets))
            )
            .foregroundStyle(by: .value("Category", netAssetsName))
            .lineStyle(StrokeStyle(lineWidth: 2)) // 增加线条厚度，突出显示
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", item.date),
                y: .value("Amount", max(0, item.netAssets))
            )
            .foregroundStyle(by: .value("Category", netAssetsName))
            .interpolationMethod(.catmullRom)
            .opacity(0.3)
        } else {
            ForEach(item.values(ignoredCategories), id: \.category) { value in
                if value.category.isLiability {
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", value.amount)
                    )
                    .foregroundStyle(by: .value("Category", value.category.name))
                    .lineStyle(StrokeStyle(lineWidth: 1)) // 增加线条厚度，突出显示
                    .interpolationMethod(.catmullRom)
                    .opacity(0.3)
                }
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", value.amount)
                )
                .foregroundStyle(by: .value("Category", value.category.name))
                .interpolationMethod(.catmullRom)
                .opacity(0.3)
            }
        }
    }
    
    var viewModeSwitchPanel: some View {
        HStack(spacing: 0) {
            modeSelectButton("全部", !isOnlyNetAssets ? Color.blue : Color(hex: "9C9C9C")) {
                if isOnlyNetAssets {  isOnlyNetAssets.toggle() }
            }
            modeSelectButton(netAssetsName, isOnlyNetAssets ? Color.blue : Color(hex: "9C9C9C")) {
                if !isOnlyNetAssets {  isOnlyNetAssets.toggle() }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    fileprivate func modeSelectButton(_ title: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Spacer()
                Text(title).font(.caption).foregroundStyle(color)
                Spacer()
            }
            .padding(5) // 内边距
            .contentShape(Rectangle()) // 让整个区域响应点击
            .overlay(
                Rectangle() // 矩形边框
                    .stroke(Color(hex: "E8E8E8"), lineWidth: 1) // 边框颜色和宽度
            )
        }
        .plainStyle()
    }
    
    @ViewBuilder
    fileprivate func timePointSummary(_ item: StackedAreaData) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 5, verticalSpacing: 5) {
            GridRow {
                Text(item.date.formatted("yyyy年MM月dd日"))
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#696969"))
                Spacer()
            }
            
            // 净资产和负债放到最上面
            GridRow {
                timePointSummaryItem(item)
                timePointSummaryItem(item, AssetCategory.liabilities)
            }
            
            ForEach(AssetCategory.allCases.filter { $0.isAsset }.chunked(into: 2), id: \.self) { rows in
                GridRow {
                    ForEach(rows) { category in
                        timePointSummaryItem(item, category)
                    }
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color(hex: "F8F8FF"))
        }
    }
    
    @ViewBuilder
    fileprivate func timePointSummaryItem(_ item: StackedAreaData, _ category: AssetCategory? = nil) -> some View {
        HStack {
            Text("\(category?.name ?? netAssetsName): \(Int(item.sumBy { category == nil ? true : $0 == category }).formatted())")
                .font(.caption2)
                .fixedSize(horizontal: true, vertical: false) // 自动调整宽度
                .foregroundStyle(Color(hex: category?.sankeyChildrenColor ?? netAssetsColor))
        }
    }
    
    
    @ViewBuilder
    private var chartLegend: some View {
        VStack {
            if isOnlyNetAssets {
                HStack(spacing: 3) {
                    Image(systemName: "square.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: netAssetsColor))
                    
                    Text(netAssetsName)
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.75))
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(AssetCategory.allCases).chunked(into: 3), id: \.self) { rows in
                        HStack(spacing: 20) {
                            // 遍历每个选项，显示为多选框
                            ForEach(rows, id: \.self) { chartLegendItem($0) }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .frame(height: 60)
        .zIndex(-1)
    }
    
    @ViewBuilder
    private func chartLegendItem(_ category: AssetCategory) -> some View {
        let isNotSelected = ignoredCategories.contains(category)
        Button(action: {
            if !isNotSelected && ignoredCategories.count == AssetCategory.allCases.count - 1 {
                return
            }
            if isNotSelected {
                ignoredCategories.remove(category)
            } else {
                ignoredCategories.insert(category)
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: isNotSelected ? "square" : "checkmark.square.fill")
                    .font(.caption)
                    .foregroundColor(isNotSelected ? .secondary.opacity(0.5) : Color(hex: category.sankeyColor).opacity(0.5))
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.75))
            }
        }
        .plainStyle()
    }
    
    private func chartColorStyleMapping(_ needGradient: Bool) -> KeyValuePairs<String, LinearGradient> {
        [
            AssetCategory.liquidAssets.name: newLinearGradient(needGradient, Color(hex: AssetCategory.liquidAssets.sankeyChildrenColor)),
            AssetCategory.investments.name: newLinearGradient(needGradient, Color(hex: AssetCategory.investments.sankeyChildrenColor)),
            AssetCategory.receivables.name: newLinearGradient(needGradient, Color(hex: AssetCategory.receivables.sankeyChildrenColor)),
            AssetCategory.fixedAssets.name: newLinearGradient(needGradient, Color(hex: AssetCategory.fixedAssets.sankeyChildrenColor)),
            AssetCategory.liabilities.name: newLinearGradient(needGradient, Color(hex: AssetCategory.liabilities.sankeyChildrenColor)),
            netAssetsName: newLinearGradient(needGradient, Color(hex: netAssetsColor)),
        ]
    }
    
    private func newLinearGradient(_ needGradient: Bool, _ color: Color) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color, needGradient ? color.opacity(0.3) : color]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // ------------------------------------------------------------------------------------------
    
    /// 图表视距范围
    /// 如果数据范围在一年内, 直接展示全部数据
    /// 如果数据范围超过一年, 只展示一年的数据
    private func dynamicDateAxisLength() -> Int? {
        let days = Date.betweenDays(startDate, endDate)
        return days > viewingDistance ?  60 * 60 * 24 * viewingDistance : nil
    }
    
    /// 废弃, 还不如用系统预设
    private func dynamicValueAxisScales(topCount: Int = 3, bottomCount: Int = 2) -> [Int] {
        if isOnlyNetAssets {
            let top = Int(data.map { $0.netAssets }.max() ?? 0)
            return NumberBins(range: 0...top, desiredCount: topCount, minimumStride: 1).thresholds
        }
        let top = Int(data.map { $0.sumBy(ignored: ignoredCategories) { $0.isAsset } }.max() ?? 0)
        let bottom = Int(data.map { $0.sumBy(ignored: ignoredCategories) { $0.isLiability } }.min() ?? 0)
        
        return NumberBins(range: bottom...0, desiredCount: bottomCount, minimumStride: 1).thresholds +
        NumberBins(range: 0...top, desiredCount: topCount, minimumStride: 1).thresholds
    }
}

struct StackedAreaData: Identifiable {
    let date: Date
    let values: [(category: AssetCategory, amount: Double)]
    
    var id: Date { date }
    
    func sumBy(ignored: Set<AssetCategory>? = nil, _ predicate: (AssetCategory) -> Bool) -> Double {
        (ignored.map { values($0) } ?? values)
            .filter { predicate($0.category) }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    var netAssets: Double { sumBy { _ in true } }
    var assets: Double { sumBy { $0.isAsset } }
    var liabilities: Double { sumBy { $0.isLiability } }
    
    func values(_ ignored: Set<AssetCategory>) -> [(category: AssetCategory, amount: Double)] {
        values.filter { !ignored.contains($0.category) }
    }
}

#Preview {
    AssetStackedAreaGraph()
        .frame(height: 350)
        .preview(months: 10, random: true)
}
