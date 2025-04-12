//
//  SwiftUIExtensions.swift
//  Observable
//
//  Created by whoog on 2024/11/11.
//

import SwiftUI
import Charts

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @ViewBuilder
    func applyIgnoringSafeArea(_ regions: SafeAreaRegions = .all, edges: Edge.Set = .all, _ apply: Bool = true) -> some View {
        if apply {
            self.ignoresSafeArea(regions, edges: edges)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func customOnAppear(_ callOnce: Bool = true, action: @escaping () -> ()) -> some View {
        self.modifier(CustomOnAppearModifier(callOnce: callOnce, action: action))
    }
    
    @ViewBuilder
    func plainStyle() -> some View {
        self.buttonStyle(PlainButtonStyle()) // 去除按钮的默认样式
    }
}

fileprivate struct CustomOnAppearModifier: ViewModifier {
    var callOnce: Bool
    var action: () -> ()
    /// View Properties
    @State private var isTriggered: Bool = false
    func body(content: Content) -> some View {
        content
            .onAppear {
                if callOnce {
                    if !isTriggered {
                        action()
                        isTriggered = true
                    }
                } else {
                    action()
                }
            }
    }
}

extension ViewModifier {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// 补丁解决隐藏返回按钮时滑动返回不可用
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

extension Chart {
    
    @ViewBuilder
    func conditionScrollable<P: Plottable & Numeric>(_ apply: Bool = true, _ axes: Axis.Set, length: P? = nil, initialX: (some Plottable)? = nil) -> some View {
        if apply {
            if let length = length, let initialX = initialX {
                self
                    .chartScrollableAxes(axes)
                    .chartXVisibleDomain(length: length)
                    .chartScrollPosition(initialX: initialX)
            } else if let length = length {
                self
                    .chartScrollableAxes(axes)
                    .chartXVisibleDomain(length: length)
            } else if let initialX = initialX {
                self
                    .chartScrollableAxes(axes)
                    .chartScrollPosition(initialX: initialX)
            } else {
                self
                    .chartScrollableAxes(axes)
            }
        } else {
            self
        }
    }
}
