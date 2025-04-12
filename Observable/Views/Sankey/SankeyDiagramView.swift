//
//  SankeyView.swift
//  Observable
//
//  Created by whoog on 2024/9/25.
//

import SwiftUI

struct SankeyDiagramView: View {
    
    @State private var config: SankeyConfig
    var compressed: Bool = true
    let isScrollEnabled: Bool
    
    init(_ config: SankeyConfig = SankeyConfig(
        linkColor: "source",
        displayMode: .headline,
        titleMode: 2,
        fontSize: 8,
        nodeWidth: 3,
        nodePadding: 5,
        extents: [40, 25, 40, 10],
        boldWidth: 3,
        dividerWidth: 2,
        assetsRectPadding: 7,
        assetsRectFontSize: 12
    ), isScrollEnabled: Bool = false) {
        self.config = config
        self.isScrollEnabled = isScrollEnabled
    }
    
    var body: some View {
        GeometryReader { geo in
            QueryView(for: Asset.self) { items in
                let (nodes, links) = Asset.mapping(items, self.config, compressed: compressed)
                
                SankeyDiagram($config, nodes, links, isScrollEnabled)
                    .ignoresSafeArea()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .zIndex(0)
            }
        }
    }
}

#Preview {
    SankeyDiagramView()
        .frame(height: 150)
        .preview()
}
