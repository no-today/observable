//
//  AssetCategoryDetailChartView.swift
//  Observable
//
//  Created by whoog on 2024/9/23.
//

import SwiftUI
import Charts

enum MonthlyChartType {
    case normal
    case growth
}

struct ChartDataForAssetMonthly: Identifiable {
    var id: String { name }
    
    var type: MonthlyChartType = .normal

    var name: String
    var isAsset: Bool
    
    var latestAmount: Double
    var lastModified: Date?
    
    var data: [MonthlyItem]
    var color: Color
}

struct MonthlyItem: Identifiable {
    let id = UUID()

    var date: Date
    var amount: Double
    
    var lastMonthAmount: Double
    var changeFromLastMonth: Int { Int(abs(amount) - abs(lastMonthAmount)) }
    
    var month: String {
        return switch date.month {
        case 1: "一"
        case 2: "二"
        case 3: "三"
        case 4: "四"
        case 5: "五"
        case 6: "六"
        case 7: "七"
        case 8: "八"
        case 9: "九"
        case 10: "十"
        case 11: "十一"
        case 12: "十二"
        default: ""
        }
    }
}

struct AssetMonthlyCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showYearPicker = false
    @State private var selectedYear = Date.now.year
    
    @State private var years: [Int] = []
    @State private var chartDatas: [ChartDataForAssetMonthly] = []
    
    func refreshUI() {
        Task {
            let years = AssetAggregateQuery.fetchYearsWithData(modelContext)
            await MainActor.run {
                self.years = years
            }
        }
    }
    
    func reloadChartDatas()  {
        Task {
            var chartDatas = AssetCategory.allCases.map { AssetAggregateQuery.aggregateForMonthlyByCategory(modelContext, $0, selectedYear) }
            chartDatas.insert(AssetAggregateQuery.aggregateForMonthlyByCategory(modelContext, nil, selectedYear), at: 0)
            chartDatas.insert(AssetAggregateQuery.aggregateForMonthlyChanges(modelContext, selectedYear), at: 0)

            await MainActor.run {
                self.chartDatas = chartDatas
            }
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 15) {
                actionBar()
                
                ForEach(chartDatas, id: \.name) { ChartView(chartData: $0) }
            }
            .padding()
        }
        .navigationTitle("资产月历")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // 隐藏默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(Color(hex: "252525"))
                })
            }
        }
        .onTapGesture {
            withAnimation {
                showYearPicker = false
            }
        }
        .onAppear {
            refreshUI()
        }
        .onChange(of: selectedYear, initial: true) {
            reloadChartDatas()
        }
    }
    
    @ViewBuilder
    private func actionBar() -> some View {
        HStack {
            Menu {
                Picker("", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            } label: {
                HStack {
                    Button(action: { withAnimation { showYearPicker.toggle() }}) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        
                        Text("\(String(selectedYear)) 年")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "triangle.fill")
                            .rotationEffect(.degrees(180)) // 旋转180度，形成倒三角形
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "828282"))
                    }
                }
                .padding(10)
                .background(Color(hex: "F2F2F2"))
                .cornerRadius(10)
            }
            
            Spacer()
        }
    }
    
    private struct ChartView: View {
        @State private var chartSelection: String?
        
        var chartData: ChartDataForAssetMonthly
        
        var body: some View {
            frame {
                Chart(chartData.data.indices, id: \.self) { index in
                    let item = chartData.data[index]
                    
                    BarMark(
                        x: .value("Key", item.month),
                        
                        /// 如果是负债，需要转成正数
                        /// 如果是资产，为负数时需要限制为0，否则展示会很奇怪
                        y: .value("Val", chartData.type == .growth ? item.amount : chartData.isAsset ? max(0, item.amount) : abs(item.amount))
                    )
                    .foregroundStyle(by: .value("Type", item.month))
                    
//                    if index == 0 {
//                        RuleMark(y: .value("Baseline", 0)) // 添加一条水平线，y 值设为 0
//                            .lineStyle(StrokeStyle(lineWidth: 0.5)) // 线条样式，可自定义
//                            .foregroundStyle(Color.gray) // 线条颜色
//                    }
                    
                    if let chartSelection, chartSelection == item.month, item.amount != 0 {
                        RuleMark(x: .value("Key", chartSelection))
                            .foregroundStyle(.clear)
                            .annotation(
                                position: .automatic,
                                overflowResolution: .init(x: .fit, y: .disabled)
                            ) { axisMarkContent(item, index) }
                    }
                }
                .chartForegroundStyleScale(range: customStyles(chartData.data, chartData.color, chartData.type))
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(position: .bottom, values: .automatic) { value in
                        AxisValueLabel() {
                            if let value = value.as(String.self) {
                                Text("\(value)").font(.system(size: 10))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3, roundLowerBound: false, roundUpperBound: false)) { value in
                        if let value = value.as(Double.self) {
                            AxisValueLabel(multiLabelAlignment: .bottomTrailing) {
                                Text(value.formatToK())
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        }
                    }
                }
                .chartXSelection(value: $chartSelection)
                .frame(height: 105)
            }
        }
        
        @ViewBuilder
        private func frame(@ViewBuilder _ content: () -> some View) -> some View {
            if let lastModified = chartData.lastModified {
                VStack {
                    HStack {
                        Text(chartData.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(chartData.color)
                        
                        if chartData.latestAmount != 0 {
                            Text(chartData.latestAmount.formatted())
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "5D5D5D"))
                        }
                        
                        Spacer()
                        
                        Text(lastModified.formatted("yyyy.MM.dd"))
                            .font(.caption)
                            .foregroundColor(Color(hex: "CCCBCF"))
                    }
                    
                    Spacer()
                    
                    content()
                }
                .padding()
                .frame(height: 200)
                .background(Color(hex: "F4F3F7"))
                .cornerRadius(15)
            }
        }

        @ViewBuilder
        private func axisMarkContent(_ item: MonthlyItem, _ index: Int) -> some View {
            VStack(alignment: .leading) {
                Text("¥ \(Int(item.amount).formatted())")
                    .font(.caption2)
                
                if chartData.type == .normal {
                    if item.changeFromLastMonth == 0 {
                        Text(verbatim: "→").font(.caption2).foregroundStyle(trendColor(chartData.isAsset, nil))
                    } else if item.changeFromLastMonth > 0 {
                        Text(verbatim: "增加 \(Int(item.changeFromLastMonth).formatted())").font(.caption2).foregroundStyle(trendColor(chartData.isAsset, true))
                    } else {
                        Text(verbatim: "减少 \(Int(item.changeFromLastMonth).formatted())").font(.caption2).foregroundStyle(trendColor(chartData.isAsset, false))
                    }
                }
            }
            .padding(7)
            .background {
                RoundedRectangle(cornerRadius: 5).foregroundStyle(Color.secondary.opacity(0.1))
            }
        }
        
        private func customStyles(_ data: [MonthlyItem], _ backgroundColor: Color, _ type: MonthlyChartType) -> [Color] {
            var colors = [Color]()
            
            var preMonthAmount = 0.0
            for item in data {
                if type == .normal {
                    // 如果对比上月没有变化，则用灰色，若有变化，则用背景色
                    if preMonthAmount == item.amount {
                        colors.append(Color(hex: "E9E9E9"))
                    } else {
                        colors.append(backgroundColor.opacity(0.2))
                    }
                } else {
                    if item.amount > 0 {
                        colors.append(trendColor(true, true).opacity(0.2))
                    } else {
                        colors.append(trendColor(true, false).opacity(0.2))
                    }
                }
                
                preMonthAmount = item.amount
            }
            
            return colors
        }
    }
}

#Preview {
    AssetMonthlyCalendarView()
        .preview(months: 13, random: true)
}
