//
//  Chart.swift
//  Observable
//
//  Created by whoog on 2024/8/20.
//
// https://swiftwithmajid.com/2023/01/18/mastering-charts-in-swiftui-mark-styling/

import SwiftUI
import Charts

struct ChartDataForAssetCategory: Identifiable {
    let id = UUID()
    
    var name: String
    var isAsset: Bool

    var amount: Double
    var lastMonthAmount: Double
    var changeFromLastMonth: Int { Int(abs(amount) - abs(lastMonthAmount)) }
    
    var backgroundColor: Color
    var textColor: Color?
}

struct AssetSummaryView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var showAssets: Bool
    
    @State var liabilities: Double = 0
    @State var netAssets: Double = 0
    @State var debtRatio: Double = 0
    @State var liquidAssets: Double = 0
    @State var lastModified: Date? = nil
    @State var liabilitiesDiff: Double = 0
    @State var netAssetsDiff: Double = 0

    @State var chartData: [ChartDataForAssetCategory] = []

    func refreshUI() {
        Task {
            let (_, liabilities, netAssets, debtRatio, liquidAssets, lastModified, liabilitiesDiff, netAssetsDiff, chartData) = AssetAggregateQuery.aggregateForSummary(modelContext)
            
            await MainActor.run {
                self.chartData = chartData
                self.liabilities = liabilities
                self.netAssets = netAssets
                self.debtRatio = debtRatio
                self.liquidAssets = liquidAssets
                self.lastModified = lastModified
                self.liabilitiesDiff = liabilitiesDiff
                self.netAssetsDiff = netAssetsDiff
            }
        }
    }
    
    var body: some View {
        VStack {
            summary
            
            VStack {
                chartHeader
                BarChartView(showAssets: $showAssets, data: chartData)
                
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)
            .background(.white)
            .cornerRadius(10)
            .onAppear {
                refreshUI()
            }
        }
    }
    
    @ViewBuilder
    var summary: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(netAssetsName)(元)")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "CCCBCF"))
                
                Button(action: {
                    showAssets.toggle()
                }, label: {
                    Image(systemName: showAssets ? "eye.slash" : "eye")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "CCCBCF"))
                })
                
                Spacer()
                
                Text(lastModified?.formatted("yyyy.MM.dd") ?? "")
                    .font(.footnote)
                    .foregroundColor(Color(hex: "CCCBCF"))
            }
            
            HStack {
                Text(showAssets ? netAssets.formatted() : "****")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 10) {
                Text(AssetCategory.liquidAssets.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "CCCBCF"))
                
                Text(showAssets ? liquidAssets.formatted() : "****")
                    .font(.subheadline.bold())
                
                Text("负债率")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "CCCBCF"))
                
                Text(showAssets ? "\(String(format: "%.2f", debtRatio))%" : "****")
                    .font(.subheadline.bold())
                    .foregroundStyle(debtRatioColor)
                
                Spacer()
            }
        }
        .padding(7)
    }
    
    private var debtRatioColor: Color {
        if debtRatio >= 70 {
            Color(hex: "#D32F2F")
        } else if debtRatio >= 50 {
            Color(hex: "#FF5722")
        } else if debtRatio >= 30 {
            Color(hex: "#FFC107")
        } else {
            Color(hex: "#4CAF50")
        }
    }
    
    @ViewBuilder
    var chartHeader: some View {
        VStack {
            let changed = netAssetsDiff != 0
            
            HStack {
                Text(changed ? "相较于上月" : "每月更新，掌握资产变化")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "5B5B5B"))
                
                Spacer()
                
                NavigationLink {
                    AssetMonthlyCalendarView()
                } label: {
                    Text("资产月历")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "C0C0C0"))
                    
                    Image(systemName: "chevron.forward")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.55))
                }
            }
            .padding(.bottom, 5)
        }
    }
    
    private struct BarChartView: View {
        @Binding var showAssets: Bool
        var data: [ChartDataForAssetCategory]
        
        var body: some View {
            Chart(data) { item in
                BarMark(
                    x: .value("Key", item.name),
                    
                    /// 如果是负债，需要转成正数
                    /// 如果是资产，为负数时需要限制为0，否则展示会很奇怪
                    y: .value("Val", item.isAsset ? max(0, item.amount) : abs(item.amount))
                )
                .foregroundStyle(by: .value("Key", item.name))
                .annotation { annotation(item) }
                .cornerRadius(2)
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale(range: customStyles(data))
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic) { value in
                    AxisValueLabel() {
                        if let value = value.as(String.self) {
                            Text("\(value)").font(.system(size: 10))
                        }
                    }
                }
            }
        }
        
        @ViewBuilder
        fileprivate func annotation(_ item: ChartDataForAssetCategory) -> some View {
            if item.amount == 0 {
                Text(verbatim: "?").font(.caption).foregroundStyle(trendColor(item.isAsset, nil))
            } else if item.changeFromLastMonth == 0 || item.lastMonthAmount == 0 {
                Text(verbatim: "→").font(.caption).foregroundStyle(trendColor(item.isAsset, nil))
            } else if item.changeFromLastMonth > 0 {
                Text(verbatim: "↑ \(showAssets ? item.changeFromLastMonth.formatted() : "****")").font(.caption).foregroundStyle(trendColor(item.isAsset, true))
            } else if item.changeFromLastMonth < 0 {
                Text(verbatim: "↓ \(showAssets ? item.changeFromLastMonth.formatted() : "****")").font(.caption).foregroundStyle(trendColor(item.isAsset, false))
            }
        }
        
        private func customStyles(_ data: [ChartDataForAssetCategory]) -> [Color] {
            data.map{ $0.backgroundColor }
        }
    }
}

func trendColor(_ isAsset: Bool, _ isUp: Bool? = nil) -> Color {
    guard let isUp else {
        return Color(hex: "9E9E9E")
    }
    
    if isUp {
        return Color(hex: isAsset ? "F44336" : "4CAF50")
    } else {
        return Color(hex: isAsset ? "4CAF50" : "F44336")
    }
}

#Preview {
    AssetSummaryView(showAssets: .constant(true))
        .frame(height: 300)
        .preview()
}
