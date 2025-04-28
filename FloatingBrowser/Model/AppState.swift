//
//  AppState.swift
//  FloatingBrowser
//
//  Created by zorth64 on 19/12/23.
//  Copyright © 2023 Andrew Finke. All rights reserved.
//

import Combine
import SwiftUI

class AppState: ObservableObject {
    @Published var title: String = ""
    @Published var isHovering: Bool = false
    @Published var isLoading: Bool = false
    @Published var showHomePage: Bool = true
    @Published private(set) var navigationRequest: NavigationRequest = .reload
    @Published var titleColor: Color = Color.gray
    @Published private(set) var dominantColors: [String: MyColor] = [:]
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var estimateProgress: CGFloat = 0.0
    @Published var userAgent: String = "" {
        didSet {
            storedUserAgent = userAgent
        }
    }
    @Published var shouldWindowFloat: Bool = true {
        didSet {
            storedShouldWindowFloat = shouldWindowFloat
        }
    }
    @Published var firstWindowId: ObjectIdentifier?
    
    @AppStorage("homePageUrl") var homePageUrl: String = ""
    @AppStorage("windowShouldFloat") private var storedShouldWindowFloat: Bool = true
    @AppStorage("searchEngineBaseUrl") var searchEngineBaseUrl: String = SearchEngine.duckDuckGo
    @AppStorage("userAgent") private var storedUserAgent: String = ""
    @AppStorage("dominantColors") private var storedDominantColors: Data?
    @AppStorage("windowPositionx") private var windowPositionX: Double = 0
    @AppStorage("windowPositionY") private var windowPositionY: Double = 0
    
    lazy var webViewDelegate: WebViewDelegate = {
        WebViewDelegate(appState: self)
    }()
    
    init() {
        title = "FloatingBrowser"
        shouldWindowFloat = self.storedShouldWindowFloat
        userAgent = self.storedUserAgent
        loadDominantColors()
        loadInitialContent()
        isHovering = true
    }
    
    private func loadInitialContent() {
        if let homePageUrl = URL(string: homePageUrl) {
            showHomePage = true
            navigationRequest = .url(url: homePageUrl)
        } else {
            showHomePage = false
            navigationRequest = .urlString(urlString: "about:blank")
        }
    }
    
    func load(_ request: NavigationRequest) {
        self.showHomePage = false
        self.navigationRequest = request
    }
}

extension AppState {
    func add(dominantColor: DominantColor) {
        guard dominantColor.host != "" else { return }
        
        dominantColors[dominantColor.host] = dominantColor.color
        saveDominantColors()
    }
    
    func isColorStored(_ url: URL) -> Bool {
        let urlString: String
        
        let host = if #available(macOS 13.0, *) {
            url.host()
        } else {
            url.host
        }
        let path = url.pathComponents.first
        urlString = "\(host ?? "")\(path ?? "")"
        return dominantColors.keys.contains(urlString)
    }
    
    func getDominantColor(fromURL url: URL) -> MyColor? {
        let urlString: String
        
        let host = if #available(macOS 13.0, *) {
            url.host()
        } else {
            url.host
        }
        let path = url.pathComponents.first
        if (isColorStored(url)) {
            urlString = "\(host ?? "")\(path ?? "")"
        } else {
            urlString = "\(host ?? "")"
        }
        return dominantColors[urlString]
    }
    
    fileprivate func loadDominantColors() {
        if let data = storedDominantColors,
           let value = try? JSONDecoder().decode([String: MyColor].self, from: data) {
                self.dominantColors = value
            print(self.dominantColors.keys.count)
        }
    }
    
    fileprivate func saveDominantColors() {
        if let data = try? JSONEncoder().encode(dominantColors) {
            self.storedDominantColors = data
        }
    }
}

extension AppState {
    var windowPosition: CGPoint {
        get {
            CGPoint(
                x: self.windowPositionX,
                y: self.windowPositionY
            )
        }
        set {
            self.windowPositionX = newValue.x
            self.windowPositionY = newValue.y
        }
    }
}
