//
//  WebViewDelegate.swift
//  FloatingBrowser
//
//  Created by zorth64 on 20/12/23.
//  Copyright © 2023 Andrew Finke. All rights reserved.
//

import Combine
import Foundation
@preconcurrency import WebKit
import SwiftUI

class WebViewDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    @Inject private var appState: AppState
    @Inject private var runtimeEvents: RuntimeEvents
    
    weak var webView: WKWebView?
    
    private var eventsSink: AnyCancellable!
    
    init(_ webView: WKWebView) {
        self.webView = webView
    }
    
    init(appState: AppState) {
        super.init()
        setKillWebViewWhenWindowCloses()
    }
    
    private func setKillWebViewWhenWindowCloses() {
        // Video playing in the WKWebView continue to play after the window
        // gets closed, this does the trick.
        eventsSink = runtimeEvents.events().sink { [weak self] event in
            guard case .closing = event else { return }
            guard let webView = self?.webView else { return }
            webView.stopLoading()
            webView.loadHTMLString("", baseURL: nil)
            self?.webView = nil
        }
    }
    
    func setup(webView: WKWebView) {
        self.webView = webView
        self.webView?.allowsBackForwardNavigationGestures = true
        self.webView?.allowsMagnification = true
        self.webView?.allowsLinkPreview = false
        self.webView?.navigationDelegate = self
        self.webView?.uiDelegate = self
        self.webView?.customUserAgent = appState.userAgent
        self.webView?.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        appState.isLoading = false
        if let myWebView = webView as? MyWebView {
//            if let url = myWebView.url {
//                myWebView.setTitleBackgroundColorFromSavedColors(fromURL: url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    myWebView.captureScreenshotAndSetBackgroundColor(fromURL: url)
                    myWebView.getDominantColorFromTop()
                }
//            }
            
            if let url = webView.url {
                if let title = webView.title {
                    if url.absoluteString  == "about:blank" {
                        DispatchQueue.main.async {
                            myWebView.setTitle("FloatingBrowser")
                        }
                    } else {
                        DispatchQueue.main.async {
                            myWebView.setTitle(title)
                        }
                    }
                }
            }
        }
    }
    
    // Lidar com erros de carregamento da página
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Erro ao carregar a página:", error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let myWebView = webView as? MyWebView {
//            if let url = myWebView.url {
//                myWebView.setTitleBackgroundColorFromSavedColors(fromURL: url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    myWebView.captureScreenshotAndSetBackgroundColor(fromURL: url)
                    myWebView.getDominantColorFromTop()
                }
//            }
        }
    }
    
    func makeDelegate() -> WebViewDelegate {
        self
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let navigationUrl = navigationAction.request.url else { return .allow }
        let urlString = navigationUrl.absoluteString.lowercased()
        
        switch urlString {
        default:
            trackPageLoad(url: navigationUrl)
            return .allow
        }
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        .allow
    }
    
    private func trackPageLoad(url: URL) {
        guard url.absoluteString == "about:blank" else { return }
        Task { @MainActor in
            appState.isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        openPanel.canChooseDirectories = false
        
        openPanel.begin { (result) in
            if result == .OK {
                completionHandler(openPanel.urls)
            } else {
                completionHandler(nil)
            }
        }
    }
}

extension NSWorkspace {
    func open(_ urlString: String) {
        if let url = URL(string: urlString) {
            open(url)
        }
    }
}
