//
//  SettingsView.swift
//  FloatingBrowser
//
//  Created by zorth64 on 25/04/25.
//  Copyright © 2025 Andrew Finke. All rights reserved.
//

import SwiftUI
import Schwifty
import WebKit

struct PreferencesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Settings").font(.title.bold()).positioned(.leading)
            HomePageSectionView()
            SearchEngineSectionView()
            WindowSectionView()
            UserAgentSectionView()
            EraseCookiesSectionView()
        }
        .padding()
    }
}

private struct HomePageSectionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        FormField(title: "HomePage URL", hint: "Leave blank to start on a blank page.") {
            TextField("about:blank", text: $appState.homePageUrl)
        }
    }
}

private struct SearchEngineSectionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        FormField(title: "Search Engine") {
            Picker(selection: $appState.searchEngineBaseUrl) {
                Text("Google").tag(SearchEngine.google)
                Text("DuckDuckGo").tag(SearchEngine.duckDuckGo)
            } label: {
                EmptyView()
            }
        }
        FormField(title: "Search Engine Base URL") {
            TextField("https://…?q=%s", text: $appState.searchEngineBaseUrl)
        }
    }
}

private struct WindowSectionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        FormField(title: "Show windows over other apps") {
            Toggle(isOn: $appState.shouldWindowFloat, label: { EmptyView() })
                .toggleStyle(.switch)
                .positioned(.leading)
        }
    }
}

private struct UserAgentSectionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        FormField(title: "User-Agent") {
            Picker(selection: $appState.userAgent) {
                Text("iPhone (Safari)").tag(UserAgent.iPhone)
                Text("iPad (Safari)").tag(UserAgent.iPad)
                Text("Mac (Safari)").tag(UserAgent.macOS)
            } label: {
                EmptyView()
            }
        }
        FormField(title: "Custom User-Agent String") {
            TextField("", text: $appState.userAgent)
        }
    }
}

private struct EraseCookiesSectionView: View {
    var body: some View {
        Button("Erase all cookies") {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
              
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records, completionHandler: {
                    
                })
            }
        }
    }
}
