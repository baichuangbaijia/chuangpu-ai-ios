import SwiftUI
import WebKit

/// 虚拟办公室 v11 - WKWebView + HTML5 Canvas
struct LobsterOfficeView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 13/255, green: 13/255, blue: 26/255, alpha: 1)
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        
        // 加载本地HTML
        if let url = Bundle.main.url(forResource: "lobster_office", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else if let path = Bundle.main.path(forResource: "lobster_office", ofType: "html") {
            web.load(URLRequest(url: URL(fileURLWithPath: path)))
        }
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
