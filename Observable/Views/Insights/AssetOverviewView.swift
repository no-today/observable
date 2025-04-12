//
//  AssetOverviewView.swift
//  Observable
//
//  Created by whoog on 2024/10/31.
//

import SwiftUI

struct AssetOverviewView: View {
    @State var showAssets = true

    var body: some View {
        frame {
            AssetSummaryView(showAssets: $showAssets)
                .frame(height: 300)
                .cardify(padding: 7, background: Color(hex: "EDEBF6"))
            
            MiniSankeyView()
            
            AssetStackedAreaGraph()
                .frame(height: 360)
                .cardify(padding: 3, title: "资产趋势")
        }
    }
    
    @ViewBuilder
    func frame(@ViewBuilder _ content: () -> some View) -> some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        header
                        content()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                
                button
            }
        }
    }
    
    @ViewBuilder
    var header: some View {
        HStack {
            Text("资产总览")
                .font(.largeTitle.bold())
            
            Spacer()
            
            HStack {
                Image("magic-sword")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 25, height: 25)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .shadow(radius: 2)
                    .offset(x: +17)
                
                Image("magic-shield")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 25, height: 25)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .shadow(radius: 2)
                
                Image(systemName: "chevron.forward")
                    .font(.subheadline)
                    .foregroundStyle(.gray.opacity(0.55))
            }
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    var button: some View {
        VStack {
            Spacer()
            
            NavigationLink {
                AssetRegistrationView()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(hex: "23A2FF"))
                    
                    Text("更新资产")
                        .font(.callout)
                        .foregroundStyle(.white)
                }
                .frame(height: 45)
                .padding()
                .background(.white)
            }
            .plainStyle()
        }
        .zIndex(1)
    }
    
    struct MiniSankeyView: View {
        let config = SankeyConfig(
            linkColor: "source",
            displayMode: .headline,
            titleMode: 2,
            fontSize: 10,
            nodeWidth: 5,
            nodePadding: 12,
            extents: [50, 20, -40, 15],
            linkOpacity: 0.2,
            boldWidth: 4,
            dividerWidth: 2,
            assetsRectPadding: 7,
            assetsRectFontSize: 14
        )
        
        var body: some View {
            VStack {
                NavigationLink(destination: SankeyFullScreenView()) {
                    SankeyDiagramView(config)
                }
                .plainStyle()
            }
            .frame(height: 200)
            .cardify(padding: 0, title: "资产组成") {
                NavigationLink(destination: SankeyFullScreenView()) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.55))
                        .rotationEffect(.degrees(90))
                        .overlay {
                            Circle().fill(.gray.opacity(0.15)).frame(width: 25, height: 25)
                        }
                }
            }
        }
    }
}

struct Cardify<ActionButton: View>: ViewModifier {
    
    var padding: Int
    var background: Color = Color.primary
    var title: String?
    var action: () -> ActionButton
    
    func body(content: Content) -> some View {
        VStack {
            header
            
            Spacer()
            content
                .padding(CGFloat(padding))
        }
        .background(background)
        .cornerRadius(15)
    }
    
    @ViewBuilder
    var header: some View {
        if let title {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color(hex: "1F1F1F"))
                
                Spacer()
                action()
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 5)
        }
    }
}

extension View {
    func cardify(padding: Int = 5, background: Color = Color(hex: "FAFAFA"), title: String? = nil, _ action: @escaping () -> some View = { Color.clear }) -> some View {
        self.modifier(Cardify(padding: padding, background: background, title: title, action: action))
    }
}

#Preview {
    AssetOverviewView()
        .preview(months: 12 * 2, random: true)
}
