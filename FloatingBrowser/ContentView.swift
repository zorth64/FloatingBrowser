//
//  ContentView.swift
//  FloatingBrowser
//
//  Created by Andrew Finke on 9/21/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Combine
import SwiftUI

struct _HackStorage {
    static var urlString: String = ""
}

struct ContentView : View {
    
    @Environment(\.controlActiveState) var activeState
    @Environment(\.colorScheme) var colorScheme

    @State var urlString: String = ""
    @State var currentUrl: URL?
    
    @EnvironmentObject var appState: AppState
    
    @FocusState var focused: Bool
    
    @State private var showProgress: Bool = false
    @State private var estimateProgress: Double = 0.0
    @State private var isFocusedWindow: Bool = true
    @State private var isShowingWebpage: Bool = false
    
    let webView = WebView()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack() {
                ZStack() {
                    if (showProgress && isShowingWebpage) {
                        GeometryReader { reader in
                            Rectangle()
                                .fill(appState.titleColor.opacity(0.25))
                                .padding(0)
                                .frame(width: .infinity, height: .infinity)
                                .mask {
                                    Rectangle()
                                        .frame(width: reader.size.width, height: .infinity)
                                        .foregroundStyle(Color.black)
                                        .offset(x: -reader.size.width + estimateProgress * reader.size.width, y: 4)
                                        .padding(0)
                                }
                        }
                        .transition(AnyTransition.opacity)
                        .frame(width: .infinity, height: .infinity)
                    }
                    
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer().frame(minWidth: 72, maxWidth: 72)
                                HStack(spacing: 4) {
                                    Button(action: {
                                        historyWebPageBack()
                                    }){
                                        Image(systemName: "chevron.backward")
                                            .font(.system(size: 14))
                                            .padding(3)
                                    }
                                    .disabled(!appState.canGoBack)
                                    Button(action: {
                                        historyWebPageForward()
                                    }){
                                        Image(systemName: "chevron.forward")
                                            .font(.system(size: 14))
                                            .padding(3)
                                    }
                                    .disabled(!appState.canGoForward)
                                }
                                .padding(.top, 8)
                                .buttonStyle(PlainTitleBarButtonStyle(color: appState.titleColor, isFocusedWindow: $isFocusedWindow))
                                Text(appState.title)
                                    .disabled(true)
                                    .font(.system(size: 13))
                                    .foregroundColor(isFocusedWindow && activeState == .key ?
                                         appState.titleColor : appState.titleColor.opacity(0.65))
                                    .padding(.top, 7)
                                    .padding(.leading, 10)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .frame(maxWidth: .infinity)
                            Spacer().frame(minWidth: 102, maxWidth: 102)
                            VStack(alignment: .trailing, spacing: 0) {
                                ShareLink(item: currentUrl ?? URL(string: "about:blank")!)
                                    .disabled(!isShowingWebpage)
                                    .labelStyle(.iconOnly)
                                    .imageScale(.medium)
                                    .font(.system(size: 14))
                                    .padding(3)
                                    .buttonStyle(SharingButtonStyle(color: appState.titleColor, isFocusedWindow: $isFocusedWindow))
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 2)
                        }
                        
                        HStack(spacing: 0) {
                            HStack(spacing: 4) {
                                Button(action: {
                                    historyWebPageBack()
                                }){
                                    Image(systemName: "chevron.backward")
                                        .font(.system(size: 14))
                                        .padding(3)
                                }
                                .disabled(!appState.canGoBack)
                                Button(action: {
                                    historyWebPageForward()
                                }){
                                    Image(systemName: "chevron.forward")
                                        .font(.system(size: 14))
                                        .padding(3)
                                }
                                .disabled(!appState.canGoForward)
                            }
                            .padding(.top, 8)
                            .buttonStyle(PlainTitleBarButtonStyle(color: appState.titleColor, isFocusedWindow: $isFocusedWindow))
                            Text(appState.title)
                                .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                                .font(.system(size: 13))
                                .foregroundColor(isFocusedWindow && activeState == .key ?
                                     appState.titleColor : appState.titleColor.opacity(0.65))
                                .padding(.top, 7)
                                .padding(.leading, 10)
                                .padding(.trailing, 7)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing, spacing: 0) {
                                ShareLink(item: currentUrl ?? URL(string: "about:blank")!)
                                    .disabled(!isShowingWebpage)
                                    .labelStyle(.iconOnly)
                                    .imageScale(.medium)
                                    .font(.system(size: 14))
                                    .padding(3)
                                    .buttonStyle(SharingButtonStyle(color: appState.titleColor, isFocusedWindow: $isFocusedWindow))
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 2)
                        }
                        .padding(.leading, 72)
                    }
                }
                .frame(maxWidth:.infinity, maxHeight: 21)
                .onChange(of: appState.estimateProgress) {
                    if (appState.estimateProgress < 1) {
                        showProgress = true
                        withAnimation(.smooth(duration: 0.15)) {
                            estimateProgress = appState.estimateProgress
                        }
                    } else {
                        estimateProgress = appState.estimateProgress
                        withAnimation(.easeInOut(duration: 0.5), {
                            showProgress = false
                        }) {
                            estimateProgress = 0.0
                        }
                    }
                }
                webView
                    .opacity(isShowingWebpage ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onReceive(NotificationCenter.default.publisher(for: .reload)) { _ in
                        if activeState == .key {
                            reloadWebPage()
                        }
                    }
                    .onAppear {
                        if (appState.showHomePage) {
                            currentUrl = URL(string:appState.homePageUrl)
                            urlString = appState.homePageUrl
                            isShowingWebpage = true
                            toggleAddressBar()
                        }
                    }
            }
            
            ZStack {
                Color.clear
                    .frame(height: 37)
                if appState.isHovering {
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: .infinity, height: 37)
                            .background {
                                BackdropLayerWrapper(effect: (colorScheme == .dark ? .dark : .mediumDark), blurRadius: 10, saturationFactor: 1.6, cornerRadius: 0)
                                    .padding(.top, -1)
                                    .overlay(colorScheme == .dark ? .black.opacity(0.25) : .clear)
                            }
                        ZStack() {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .padding(.leading, 6)
                                    .foregroundColor(Color.primary.opacity(0.8))
                                TextField("Search or type URL", text: $urlString)
                                    .foregroundColor(.primary)
                                    .onSubmit(searchOrVisit)
                                    .focused($focused)
                                    .onAppear { focused = true }
                                    .textFieldStyle(.plain)
                            }
                            .font(.system(size: 13))
                            .frame(height: 24)
                            .background {
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder((colorScheme == .dark ? Color.black : Color.white).opacity(0.35), lineWidth: 1)
                                    .background {
                                        Rectangle()
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.35))
                                            .cornerRadius(5)
                                    }
                                    
                            }
                        }
                        .padding(.top, 3)
                        .padding(.leading, 7)
                        .padding(.trailing, 7)
                        .padding(.bottom, 4)
                    }
                    .transition(AnyTransition.move(edge: Edge.bottom))
                    .onSubmit(searchOrVisit)
                    .onChange(of: focused) {
                        if (!focused && activeState == .key) {
                            toggleAddressBar()
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleURLField)) { _ in
                if (activeState == .key) {
                    toggleAddressBar()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .urlChanged)) { newUrl in
                if activeState == .key {
                    if let newURL = newUrl.object as? URL {
                        if (newURL.absoluteString != "about:blank") {
                            urlString = newURL.absoluteString
                            currentUrl = newURL
                        } else {
                            currentUrl = URL(string: "about:blank")
                            urlString = ""
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { (_) in
                isFocusedWindow = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { (_) in
                isFocusedWindow = false
            }
            
            Button {
                toggleAddressBar()
            } label: {
                Image(systemName: "square.topthird.inset.filled")
            }
            .keyboardShortcut(.init("L"), modifiers: [.command])
            .opacity(0)
        }
        .onHover { isHovering in
            if !isHovering {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.isHovering = isHovering
                }
            }
        }
        .background {
//            if (reduceTransparency) {
//                Rectangle()
//                    .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.12, opacity: 0.85) :
//                            Color(red: 0.93, green: 0.93, blue: 0.93, opacity: 0.85))
//                    .padding(.bottom, -1)
            if (!isShowingWebpage) {
                BackdropLayerWrapper(effect: (colorScheme == .dark ? .ultraDark : .light), blurRadius: 5, saturationFactor: 1.6, cornerRadius: 5)
                //                    .overlay(colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.3))
                    .padding(.bottom, -1)
            }
//            } else {
//                VisualEffectView()
//                    .overlay(colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.3))
//                    .ignoresSafeArea()
//            }
        }
    }
    
    private func searchOrVisit() {
        let trimmedInput: String?
        if !(urlString.hasPrefix("https://") || urlString.hasPrefix("http://")) {
            let ipRegex = (try? Regex("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}.*"))!
            if urlString.starts(with: ipRegex) {
                trimmedInput = "http://\(urlString.trimmingCharacters(in: .whitespacesAndNewlines))"
            } else {
                trimmedInput = "https://\(urlString.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
        } else {
            trimmedInput = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let url = URL(string: trimmedInput!), url.scheme != nil, url.host != nil {
            if url.absoluteString != "about:blank" {
                isShowingWebpage = true
                appState.load(.url(url: url))
            }
        } else {
            isShowingWebpage = true
            appState.load(.search(input: trimmedInput!))
        }
        closeAddressBar()
    }
    
    private func closeAddressBar() {
        appState.title = "Loading..."
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.isHovering = false
        }
    }
    
    func toggleAddressBar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.isHovering.toggle()
        }
    }
    
    func reloadWebPage() {
        appState.load(.reload)
    }
    
    func historyWebPageBack() {
        appState.load(.back)
    }
    
    func historyWebPageForward() {
        appState.load(.forward)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
