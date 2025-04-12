//
//  SwiftUIView.swift
//
//
//  Created by no-today on 2024/6/14.
//

import SwiftUI
import WebKit

struct SankeyDiagram: UIViewRepresentable {
    @Binding var config: SankeyConfig
    
    var nodes: [SankeyNode]
    var links: [NodeLink]
    let isScrollEnabled: Bool
    
    @State private var isWebViewInitialized = false  // 标识符
    
    init(_ config: Binding<SankeyConfig>, _ nodes: [SankeyNode], _ links: [NodeLink], _ isScrollEnabled: Bool = true) {
        self._config = config
        self.nodes = nodes
        self.links = links
        self.isScrollEnabled = isScrollEnabled
    }
    
    // Swift UI & Javascript Two-way communication: https://gist.github.com/JSerZANP/ea300d419bfafa79e4f8c0af42d8fec6
    // Define any method to call: https://stackoverflow.com/a/56325336/12679246
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var webView: WKWebView?
        var parent: SankeyDiagram
        
        init(_ parent: SankeyDiagram) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
            parent.refreshUI(webView, "Initialize")
        }
        
        // Receive message from webview
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Mark WebView as initialized
            DispatchQueue.main.async {
                self.parent.isWebViewInitialized = true
                print("[WebView] Received: \(message.body)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let coordinator = makeCoordinator()
        let userContentController = WKUserContentController()
        userContentController.add(coordinator, name: "bridge")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        // 注入本地 JavaScript 文件
        if let jsURL = Bundle.main.url(forResource: "runtime", withExtension: "js"),
           let jsContent = try? String(contentsOf: jsURL) {
            let userScript = WKUserScript(source: jsContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            configuration.userContentController.addUserScript(userScript)
        }
        
        let _wkwebview = WKWebView(frame: .zero, configuration: configuration)
        _wkwebview.navigationDelegate = coordinator
        _wkwebview.isOpaque = false
        _wkwebview.scrollView.showsVerticalScrollIndicator = false
        _wkwebview.scrollView.showsHorizontalScrollIndicator = false
        _wkwebview.scrollView.contentInset = .zero
        _wkwebview.scrollView.contentInsetAdjustmentBehavior = .never
        _wkwebview.scrollView.scrollIndicatorInsets = .zero
        
        // Enable both horizontal and vertical scrolling
        _wkwebview.scrollView.isDirectionalLockEnabled = false
        _wkwebview.scrollView.isScrollEnabled = isScrollEnabled
        _wkwebview.scrollView.bounces = isScrollEnabled
        _wkwebview.scrollView.alwaysBounceVertical = isScrollEnabled
        _wkwebview.scrollView.alwaysBounceHorizontal = isScrollEnabled

        if let htmlPath = Bundle.main.path(forResource: "d3-sankey", ofType: "html") {
            let htmlUrl = URL(fileURLWithPath: htmlPath)
            _wkwebview.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        } else {
            print("[Sankey] Html resource is not found")
        }
        
        return _wkwebview
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if isWebViewInitialized && !nodes.isEmpty && !links.isEmpty {
            refreshUI(webView)
        }
    }
    
    fileprivate func refreshUI(_ webView: WKWebView, _ tag: String = "Refresh") {
        if (nodes.isEmpty || links.isEmpty) {
            return
        }
        
        var _config = config
        if (_config.width == 0 || _config.height == 0) {
            // 默认使用视图宽高
            _config.width = webView.bounds.width
            _config.height = webView.bounds.height
        }
        _config.nodePaddingScaleForNodes(config.nodePadding, nodes.count)
        
        let cfg = JSON.toJSONString(_config) ?? ""
        let ns = JSON.toJSONString(nodes) ?? ""
        let ls = JSON.toJSONString(links) ?? ""
        
//        print("\(tag) NodePadding: \(_config.nodePadding), nodes: \(nodes.count)")
//        print("\(tag) Width: \(_config.width), Height: \(_config.height)")
//        print("\(tag) Config: \(cfg)")
//        print("\(tag) Nodes: \(ns)")
//        print("\(tag) Links: \(ls)")
 
        webView.evaluateJavaScript("drawSankeyDiagram(\(cfg), \(ns), \(ls))") { result, error in
            if let error = error {
                print("[Sankey] \(tag) error: \(error)")
            } else {
                //print("[Sankey] \(tag) success")
            }
        }
    }
}

#Preview {
    SankeyDiagram(.constant(SankeyConfig(width: 700, height: 350)), nodes, links)
        .ignoresSafeArea()
}

#Preview("Compress") {
    SankeyDiagram(.constant(SankeyConfig(width: 700, height: 350)), nodes1, links1)
        .ignoresSafeArea()
}
