//
//  WebView.swift
//  FloatingBrowser
//
//  Created by zorth64 on 26/04/25.
//  Copyright © 2025 Andrew Finke. All rights reserved.
//

import Combine
import SwiftUI
import WebKit

struct WebView : NSViewRepresentable {

    typealias NSViewType = WKWebView
    
    @EnvironmentObject var appState: AppState
    
    var requestsSink: AnyCancellable!

    func makeNSView(context: NSViewRepresentableContext<WebView>) -> WebView.NSViewType {
        return MyWebView(appState: appState)
    }

    func updateNSView(_ nsView: WebView.NSViewType, context: NSViewRepresentableContext<WebView>) {
        //
    }

}

class MyWebView : WKWebView, WKScriptMessageHandler {
    let appState: AppState
    
    private var requestsSink: AnyCancellable!
    private var userAgentSink: AnyCancellable!
    
    private var canGoBackObservationToken: NSKeyValueObservation?
    private var canGoForwardObservationToken: NSKeyValueObservation?
    private var estimateProgressObservationToken: NSKeyValueObservation?
    private var urlObservationToken: NSKeyValueObservation?
    private var webPageTitleObservationToken: NSKeyValueObservation?
    
    private var currentUrl: URL?
    
    init(appState: AppState) {
        Dependencies.setup()
        
        self.appState = appState
        
        // Código usado para injetar códigos javascript ao carregar a página Web
        let javascript = """
        \(JavaScriptUtils.html2canvas)
        
        const topMargin = 20;
        
        function inject() {
            document.documentElement.style.setProperty('--viewport-height', `calc(100vh - ${topMargin}px)`);
        
            Object.defineProperty(window, 'screen', { value: { width: window.innerWidth, height: window.innerHeight } });
            window.onresize = function() {Object.defineProperty(window, 'screen', { value: { width: window.innerWidth, height: window.innerHeight } });}
        }
        
        inject();

        var observedElement = document.body;
        var observer = new MutationObserver(inject);
        var observerOptions = { childList: true, subtree: true };
        observer.observe(observedElement, observerOptions);
        """
        
        let userScript = WKUserScript(source: javascript,
                                              injectionTime: .atDocumentStart,
                                              forMainFrameOnly: true)
        
        let userCSS = """
        if (window.location.href === 'about:blank') {
            \(JavaScriptUtils.injectStyleTag("""
            @media (prefers-color-scheme: dark) {\
                body {\
                    background: #282828 !important;\
                }\
            }\
            body {\
                background: #FFF;\
            }
            """))
        }
        \(JavaScriptUtils.injectStyleTag("""
        * {\
        backdrop-filter: none !important;\
        -webkit-backdrop-filter: none !important;\
        }
        """))
        if (window.location.href.startsWith('https://x.com/')) {
        \(JavaScriptUtils.injectStyleTag("""
        .css-175oi2r.r-1igl3o0.r-qklmqi.r-1adg3ll.r-1ny4l3l > .css-175oi2r:not(.r-1777fci.r-1pl7oy7.r-13qz1uu.r-1loqt21.r-o7ynqc.r-6416eg.r-1ny4l3l) > .css-175oi2r:not(article:first-child):not(.r-18u37iz.r-1udh08x.r-1c4vpko.r-1c7gwzm.r-o7ynqc.r-6416eg.r-1ny4l3l.r-1loqt21):not([data-testid="inline_reply_offscreen"]):not(button), .css-175oi2r[data-testid="cellInnerDiv"] > .css-175oi2r.r-1adg3ll.r-1ny4l3l > .css-175oi2r > .css-175oi2r.r-kemksi,\
        .css-175oi2r+.css-146c3p1.r-dnmrzs.r-1udh08x.r-3s2u2q.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-adyw6z.r-135wba7.r-16dba41.r-dlybji.r-nazi8o,\
        .css-175oi2r+.css-146c3p1.r-dnmrzs.r-1udh08x.r-3s2u2q.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-adyw6z.r-135wba7.r-b88u0q.r-dlybji.r-nazi8o.r-1nao33i,\
        button.css-175oi2r.r-1awozwy.r-sdzlij.r-6koalj.r-18u37iz.r-xyw6el.r-1loqt21.r-o7ynqc.r-6416eg.r-1ny4l3l > .css-175oi2r.r-obd0qt.r-16y2uox,\
        button.css-175oi2r.r-1awozwy.r-sdzlij.r-6koalj.r-18u37iz.r-xyw6el.r-1loqt21.r-o7ynqc.r-6416eg.r-1ny4l3l > .css-175oi2r.r-1wbh5a2.r-dnmrzs.r-1ny4l3l,\
        .css-175oi2r.r-1habvwh.r-18u37iz.r-1wtj0ep.r-lgtrmy.r-f8sm7e.r-13qz1uu.r-ubg91z,\
        div.css-175oi2r > div.css-175oi2r[data-testid="placementTracking"],\
        .css-175oi2r.r-u8s1d[data-testid="hoverCardParent"],\
        [data-testid="super-upsell-UpsellButtonRenderProperties"] {\
            display: none !important;\
        }\
        header.css-175oi2r.r-lrvibr.r-1g40b8q.r-obd0qt.r-16y2uox, header > .css-175oi2r.r-o96wvk, .r-o96wvk {\
            width: 70px !important;\
        }\
        .r-64el8z {\
            min-width: 50px !important;\
        }\
        .r-4wgw6l {\
            min-width: 50px !important;\
        }\
        .css-175oi2r.r-l00any.r-e7q0ms {\
            width: 25px !important;\
        }\
        .r-1fkl15p {\
            padding-left: 5px !important;\
            padding-right: 5px !important;\
        }\
        .css-175oi2r.r-184id4b > .css-175oi2r > button.css-175oi2r.r-1awozwy.r-sdzlij.r-6koalj.r-18u37iz.r-xyw6el.r-1loqt21.r-o7ynqc.r-6416eg.r-1ny4l3l {\
            padding-left: 5px !important;\
        }\
        .r-135wba7[data-testid="tweetText"], .r-rjixqe[data-testid="tweetText"], .r-a8ghvy,\
        .css-146c3p1.r-8akbws.r-krxsd3.r-dnmrzs.r-1udh08x.r-1udbk01.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6.r-rjixqe.r-16dba41 {\
            line-height: 1.5em !important;\
        }\
        .r-1inkyih[data-testid="tweetText"] {\
            font-size: 19px !important;\
        }\
        .r-a023e6[data-testid="tweetText"],\
        .css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6.r-rjixqe.r-16dba41,\
        .css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6.r-16dba41.r-1kt6imw.r-dnmrzs,\
        .css-146c3p1.r-bcqeeo.r-1ttztb7.r-qvutc0.r-37j5jr.r-a023e6.r-16dba41.r-1adg3ll.r-a8ghvy.r-p1pxzi {\
            font-size: 17px !important;\
        }\
        /*.r-1inkyih .r-qlhcfr, .r-a023e6 .r-qlhcfr {\
            opacity: 0.6;\
        }*/\
        div[role="tablist"] .r-1b43r93 {\
            font-size: 14px !important;\
            line-height: auto !important;\
        }
        """))
        }
        if (window.location.href.startsWith('https://megacanais.com/')) {
        \(JavaScriptUtils.injectScriptTag("""
        minhaFuncao();

        function minhaFuncao() {

        var el = document.querySelector("#is-popup-wrapper");
        if (el != null) {
        el.remove();
        }

        Array.prototype.slice.call(document.querySelectorAll('script+a')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('link[id^="ivory-ajax-"]+script+script')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('div.code-block')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('div[style*="position: absolute;"]')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('iframe[style*="position: absolute;"]')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('script[id^="rocket-"]')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('script[async="true"]')).forEach(function(el) {el.remove();});

        Array.prototype.slice.call(document.querySelectorAll('script[data-adel="useng"]')).forEach(function(el) {el.remove();});

        Array.prototype.slice.call(document.querySelectorAll('body +iframe')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('link[rel="dns-prefetch"]')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('link[rel="preconnect"]')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('script[data-cfasync="false"]')).forEach(function(el) {el.remove()});

        Array.prototype.slice.call(document.querySelectorAll('script[async]')).forEach(function(el) {el.remove()});

        }

        var observedElement = document;

        var observer = new MutationObserver(minhaFuncao);

        var config = {
            childList: true,
            subtree: true
        };

        observer.observe(observedElement, config);

        """))
        }
        """
        
        let userStyle = WKUserScript(source: userCSS,
                                     injectionTime: .atDocumentEnd,
                                     forMainFrameOnly: true)
        
        let userContentController = WKUserContentController()
        
        userContentController.addUserScript(userScript)
        userContentController.addUserScript(userStyle)
        
//        let date = NSDate(timeIntervalSince1970: 0)
//        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: date as Date, completionHandler:{ })
        let datastore = WKWebsiteDataStore.default()
        
        let config = WKWebViewConfiguration()
        let pref = WKWebpagePreferences.init()
        pref.preferredContentMode = .mobile
        config.defaultWebpagePreferences = pref
        config.userContentController = userContentController
        
        config.websiteDataStore = datastore
        
        super.init(frame: CGRect.zero, configuration: config)
        
        estimateProgressObservationToken = self.observe(\.estimatedProgress) { (object, change) in
            appState.estimateProgress =  self.estimatedProgress
        }
        canGoBackObservationToken = self.observe(\.canGoBack) { (object, change) in
            appState.canGoBack = self.canGoBack
        }
        canGoForwardObservationToken = self.observe(\.canGoForward) { (object, change) in
            appState.canGoForward = self.canGoForward
        }
        urlObservationToken = self.observe(\.url) { (object, change) in
            if let url = self.url {
                NotificationCenter.default.post(name: .urlChanged, object: url)
                self.currentUrl = url
                if (url.absoluteString != "about:blank" && url.scheme != nil && url.host != nil) {
                    self.setTitleBackgroundColorFromSavedColors(fromURL: self.currentUrl!)
                }
            }
        }
        webPageTitleObservationToken = self.observe(\.title) { (object, change) in
            if let title = self.title {
                if (appState.estimateProgress < 1) {
                    self.setTitle("Loading...")
                } else {
                    self.setTitle(title)
                }
            }
        }
        
        appState.webViewDelegate.setup(webView: self)
        bindUserAgent()
        bindNavigationRequests()
        configureMessageHandler()
    }
    
    private func configureMessageHandler() {
        // Adiciona o script de usuário para manipular as mensagens do JavaScript
        let userContentController = self.configuration.userContentController
        userContentController.add(self, name: "jsHandler")
    }
    
    // Método que recebe mensagens do JavaScript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "jsHandler", let messageBody = message.body as? [String: Any] {
            // Acessando as propriedades do dicionário
            if let r = messageBody["r"] as? CGFloat,
               let g = messageBody["g"] as? CGFloat,
               let b = messageBody["b"] as? CGFloat {
                
                if (self.currentUrl?.absoluteString != "about:blank") {
                    // Usando os valores para configurar a cor
                    setTitleBackgroundColor(fromURL: currentUrl!, color: NSColor(red: r / 255.0,
                                                                                 green: g / 255.0,
                                                                                 blue: b / 255.0,
                                                                                 alpha: 1.0))
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindUserAgent() {
        userAgentSink = appState.$userAgent.sink { userAgent in
            self.customUserAgent = userAgent
            self.reload()
        }
    }
    
    private func bindNavigationRequests() {
        requestsSink = appState.$navigationRequest.sink { request in
            Task { @MainActor in
                self.load(request)
            }
        }
    }
    
    func load(_ request: NavigationRequest) {
        switch request {
        case .reload: reload()
        case .html(let text, let url): loadHTMLString(text, baseURL: url)
        case .url(let url): do {
            print("\(url.host() ?? "")/\(url.pathComponents.first ?? "")")
            if appState.isColorStored(url) {
                self.setTitleColorForBG(color: NSColor(appState.getDominantColor(fromURL: url)!.getColor))
            }
            load(URLRequest(url: url))
        }
        case .urlString(let urlString): load(urlString)
        case .search(let userInput): search(userInput)
        case .back: goBack()
        case .forward: goForward()
        }
    }
    
    private func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            load(.url(url: url))
        }
    }
    
    private func search(_ userInput: String) {
        let url: URL?
        let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let inputUrl = URL(string: text), inputUrl.scheme != nil {
            url = inputUrl
        } else {
            let param = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let urlString = "\(appState.searchEngineBaseUrl)\(param ?? "")"
            url = URL(string: urlString)
        }
        if let url = url {
            load(URLRequest(url: url))
        }
    }
    
    func captureScreenshotAndSetBackgroundColor(fromURL: URL) {
        captureScreenshot { [weak self] (image) in
            guard let self = self, let image = image else { return }

            if let dominantColor = image.dominantColorFromTop() {
                DispatchQueue.main.async {
                    let isSavedColor = self.appState.isColorStored(fromURL)
                    self.setTitleColorForBG(color: dominantColor)
                    if !isSavedColor {
                        self.appState.add(dominantColor: fromURL.asDominantColor(color: Color(dominantColor)))
                    }
                }
            }
        }
    }
    
    func setTitleBackgroundColorFromSavedColors(fromURL: URL) {
        if let savedColor = self.appState.getDominantColor(fromURL: fromURL) {
            self.setTitleColorForBG(color: NSColor(savedColor.getColor))
        } else {
//            let systemAppearance: NSAppearance = NSApplication.shared.effectiveAppearance
//            if systemAppearance.name == NSAppearance.Name.darkAqua {
//                self.setTitleColorForBG(color: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0))
//            } else {
            self.setTitleColorForBG(color: NSColor.windowBackgroundColor)
//            }
        }
    }
    
    func setTitleBackgroundColor(fromURL: URL, color: NSColor) {
        if let savedColor = self.appState.getDominantColor(fromURL: fromURL) {
            if savedColor.isEqual(color: color) {
                self.setTitleColorForBG(color: savedColor.asNSColor)
            } else {
                self.setTitleColorForBG(color: color)
                self.appState.add(dominantColor: fromURL.asDominantColor(color: Color(color)))
            }
        } else {
            self.setTitleColorForBG(color: color)
            self.appState.add(dominantColor: fromURL.asDominantColor(color: Color(color)))
        }
    }
    
    private func setTitleColorForBG(color: NSColor) {
        self.window?.backgroundColor = color
        
        let luminance = color.getLuminance()
        
        self.appState.titleColor = if luminance > 0.5 {
            Color.black.opacity(0.5)
        } else {
            Color.white.opacity(0.8)
        }
    }
    
    func setTitle(_ title: String) {
        self.appState.title = title
    }
    
    private func setTitle(_ titleColor: Color) {
        self.appState.titleColor = titleColor
    }
    
}

extension WKWebView {
    func captureScreenshot(completion: @escaping (NSImage?) -> Void) {
        takeSnapshot(with: nil) { (image, error) in
            if let image = image {
                completion(image)
            } else {
                print("Failed to capture screenshot: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    func getDominantColorFromTop() {
        self.evaluateJavaScript(JavaScriptUtils.injectHtml2canvas)
    }
}

extension NSImage {
    func dominantColorFromTop() -> NSColor? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let totalBytes = height * bytesPerRow

        guard let pixelData = malloc(totalBytes) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            free(pixelData)
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        let topPixelData = pixelData.assumingMemoryBound(to: UInt8.self)
        let offset = 0 // Offset to the topmost pixel

        let red = CGFloat(topPixelData[offset]) / 255.0
        let green = CGFloat(topPixelData[offset + 1]) / 255.0
        let blue = CGFloat(topPixelData[offset + 2]) / 255.0
        let alpha = CGFloat(topPixelData[offset + 3]) / 255.0

        free(pixelData)

        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension NSColor {
    func getLuminance() -> CGFloat {
        guard let rgbColor = usingColorSpace(NSColorSpace.genericRGB) else { return 0.0 }

        let r = rgbColor.redComponent
        let g = rgbColor.greenComponent
        let b = rgbColor.blueComponent

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)

        return (maxVal + minVal) / 2.0
    }
}
