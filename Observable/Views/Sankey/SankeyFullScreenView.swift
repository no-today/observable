//
//  SankeyView.swift
//  Observable
//
//  Created by no-today on 2024/6/17.
//

import SwiftUI

struct SankeyFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var config: SankeyConfig
    
    init(_ config: SankeyConfig = SankeyConfig()) {
        self.config = config
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                topFloatActionBar()
                sankey()
            }
            .rotationEffect(.degrees(90), anchor: .bottomLeading)
            .frame(width: geo.size.height, height: geo.size.width)
            .offset(y: -geo.size.width)
            .navigationBarBackButtonHidden()
            .ignoresSafeArea(.all)
            .statusBar(hidden: true)
        }
        .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    private func sankey() -> some View {
        GeometryReader { geo in
            QueryView(for: Asset.self) { items in
                let (nodes, links) = Asset.mapping(items, self.config)
                
                SankeyDiagram($config, nodes, links)
                    .ignoresSafeArea()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .zIndex(0)
            }
            .zIndex(0)
        }
    }
    
    @ViewBuilder
    private func topFloatActionBar() -> some View {
        VStack {
            HStack(spacing: 20) {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .padding()
                })
                
                Picker("Select Display Mode", selection: $config.displayMode) {
                    ForEach(DisplayMode.allCases.filter({ $0.id != 3 }), id: \.self) { mode in
                        Text(mode.name).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                
                Button(action: {
                    
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                        .overlay {
                            Circle().fill(.gray.opacity(0.1)).frame(width: 30, height: 30)
                        }
                        .padding()
                })
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .zIndex(1)
    }
}

#Preview {
    SankeyFullScreenView().preview()
}
