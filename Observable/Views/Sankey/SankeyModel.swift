//
//  SankeyNode.swift
//
//
//  Created by no-today on 2024/6/17.
//

struct SankeyNode: Codable {
    
    /// Node name
    var name: String
    
    /// Node color, used to control the color of rectangle node
    var color: String
    
    /// Special marks
    ///   1: Total assets
    ///   2: Net assets
    ///   3: Debt
    var tag: Int?
}

struct NodeLink: Codable {
    
    /// Starting point of data flow, is the node name
    var source: String
    
    /// The end point of the data flow
    var target: String
    
    /// Numerical value
    var value: Double
}

let netAssetsName = "净资产"
let netAssetsColor = "#6BCDAD"

struct SankeyConfig: Codable {
    
    /// The color used to control the filling between the source node and the target node
    ///   - static: No color, default gray
    ///   - source-target: Creates a gradient for the source-target color option.
    ///   - source: Use source color
    ///   - target: Use target color
    var linkColor: String = "source"
    
    /// Alignment
    /// - sankeyLeft
    /// - sankeyRight
    /// - sankeyCenter
    /// - sankeyJustify
    var nodeAlign: String = "sankeyJustify"
    
    /// Amount display mode
    ///   0: Hide amount
    ///   1: Show amount
    ///   2: Percentage of display amount
    var displayMode: DisplayMode = .percentage
    
    /// Asset title location
    ///   1: Always Left,
    ///   2: Left and right
    var titleMode: Int = 2
    
    /// When building data in the application layer, it is necessary.
    var netAssetsText: String = netAssetsName
    var netAssetsNodeColor: String = netAssetsColor
    
    var totalDebtNodeColor: String = "#A6A6B0"
    var totalAssetsText: String = "总资产"
    var totalDebtText: String = "负债"
    var totalAssetsTextColor: String = "#6565A4"
    var totalDebtTextColor: String = "#81808F"
    
    /// Width of the chart view
    var width: Double = 0
    
    /// Height of the chart view
    var height: Double = 0
    
    /// Global font size
    var fontSize: Int = 12
    
    /// Width of the rectangle node
    var nodeWidth: Int = 7
    
    /// Node vertical spacing
    var nodePadding: Int = 30
    
    /// The distance between the title and the rectangle
    var titlePadding: Int = 5
    
    /// White space around
    /// [x0, y0, x1, y1]
    var extents: [Int] = [170, 120, 140, 65]
    
    var linkOpacity: Double = 0.4
    
    /// Total assets rectangle extra bold width, based on the node width
    var boldWidth: Int = 5
    
    /// Total assets additional interval width, based on the node width
    var dividerWidth: Int = 0
    
    /// Summary box height
    var assetsRectHeight: Int = 45
    
    /// Summary box width
    var assetsRectWidth: Int = 65
    
    var assetsRectPadding: Int = 20
    var assetsRectCornerRadius: Int = 5
    var assetsRectTextX: Int = 7
    var assetsRectTextDy: Double = 1.3
    var assetsRectTextDy2: Double = 2.5
    var assetsRectFontSize: Int = 14
    var assetsRectFontSize2: Int = 14
    
    /// 根据节点数量动态设定垂直 padding
    /// - 节点数量越多, padding 值需要缩小, 不然放不下那么多内容会造成重叠
    mutating func nodePaddingScaleForNodes(_ benchmark: Int, _ count: Int) {
        let scaleFactor: Double
        if count <= 10 {
            scaleFactor = 1.0
        } else {
            scaleFactor = 1.0 / (Double(count - 9) * 0.1 + 1.0) // 倒数函数平滑缩小 padding
        }
        
        self.nodePadding = Int(Double(benchmark) * scaleFactor)
    }
}

enum DisplayMode: String, CaseIterable, Codable {
    case show = "金额"
    case percentage = "比例"
    case hide = "隐藏金额"
    case headline = "标题"
    
    var id: Int {
        switch self {
        case .hide: return 0
        case .show: return 1
        case .percentage: return 2
        case .headline: return 3
        }
    }
    
    var name: String { rawValue }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
}

let nodes = [
    SankeyNode(name: "总资产", color: "#9191BE", tag: 1),
    SankeyNode(name: "信用卡", color: "#A8A7B0", tag: 3),
    SankeyNode(name: "房屋贷款", color: "#A8A7B0", tag: 3),
    SankeyNode(name: "车辆贷款", color: "#A8A7B0", tag: 3),
    SankeyNode(name: "个人贷款", color: "#A8A7B0", tag: 3),
    SankeyNode(name: "净资产", color: "#81CDB4", tag: 2),
    SankeyNode(name: "投资理财", color: "#908DA2"),
    SankeyNode(name: "后备隐藏能源", color: "#716C89"),
    SankeyNode(name: "固定资产", color: "#839FAD"),
    SankeyNode(name: "房产(自住)", color: "#5C8FA1"),
    SankeyNode(name: "汽车", color: "#5C8FA1"),
    SankeyNode(name: "应收款", color: "#908DA2"),
    SankeyNode(name: "借给他人的钱", color: "#716C89")
]

let links = [
    NodeLink(source: "信用卡", target: "总资产", value: 3000),
    NodeLink(source: "房屋贷款", target: "总资产", value: 500000),
    NodeLink(source: "车辆贷款", target: "总资产", value: 40000),
    NodeLink(source: "个人贷款", target: "总资产", value: 30000),
    NodeLink(source: "总资产", target: "固定资产", value: 850000),
    NodeLink(source: "固定资产", target: "房产(自住)", value: 800000),
    NodeLink(source: "固定资产", target: "汽车", value: 50000),
    NodeLink(source: "总资产", target: "投资理财", value: 50000),
    NodeLink(source: "总资产", target: "应收款", value: 20000),
    NodeLink(source: "投资理财", target: "后备隐藏能源", value: 50000),
    NodeLink(source: "应收款", target: "借给他人的钱", value: 20000)
]

let nodes1 = [
    SankeyNode(name: "总资产", color: "#A4A3AB", tag: 1),
    SankeyNode(name: "4项负债", color: "#A8A7B0", tag: 3),
    SankeyNode(name: "净资产", color: "#81CDB4", tag: 2),
    SankeyNode(name: "投资理财", color: "#908DA2"),
    SankeyNode(name: "后备隐藏能源", color: "#716C89"),
    SankeyNode(name: "固定资产", color: "#839FAD"),
    SankeyNode(name: "房产(自住)", color: "#F4F3F700"),
    SankeyNode(name: "汽车", color: "#F4F3F700"),
    SankeyNode(name: "应收款", color: "#F4F3F700"),
    SankeyNode(name: "借给他人的钱", color: "#F4F3F700")
]

let links1 = [
    NodeLink(source: "4项负债", target: "总资产", value: 573000),
    NodeLink(source: "总资产", target: "固定资产", value: 850000),
    NodeLink(source: "固定资产", target: "房产(自住)", value: 800000),
    NodeLink(source: "固定资产", target: "汽车", value: 50000),
    NodeLink(source: "总资产", target: "投资理财", value: 50000),
    NodeLink(source: "总资产", target: "应收款", value: 20000),
    NodeLink(source: "投资理财", target: "后备隐藏能源", value: 50000),
    NodeLink(source: "应收款", target: "借给他人的钱", value: 20000)
]
