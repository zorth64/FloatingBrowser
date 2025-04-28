//
//  AppDelegate.swift
//  FloatingBrowser
//
//  Created by Andrew Finke on 9/21/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @Inject private var appState: AppState
    
    let nc = NotificationCenter.default
    
    var windowControllers: [WindowController] = []
    
    var preferencesWindow: NSWindow?

    fileprivate func openNewWindow() {
        let window = FloatingBrowserWindow(
            contentRect: NSRect(x: 0, y: 0, width: 499, height: 800),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView
            ],
            backing: .buffered, defer: false)
        
        let windowController = WindowController(window: window)
        windowControllers.append(windowController)
        windowController.showWindow(self)
        
        if (appState.firstWindowId == nil) {
            appState.firstWindowId = ObjectIdentifier(window)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        openNewWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    @IBAction func openNewWindow(_ sender: NSMenuItem) {
        openNewWindow()
    }
    
    @IBAction func toggleAddressBar(_ sender: NSMenuItem) {
        nc.post(name: .toggleURLField, object: nil)
    }
    
    @IBAction func reloadWebView(_ sender: NSMenuItem) {
        nc.post(name: .reload, object: nil)
    }
    
    @IBAction func historyBack(_ sender: NSMenuItem) {
        nc.post(name: .historyBack, object: nil)
    }
    
    @IBAction func historyForward(_ sender: NSMenuItem) {
        nc.post(name: .historyForward, object: nil)
    }
    
    @IBAction func preferences(_ sender: Any?) {
        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
                .environmentObject(appState)
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 340),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.level = .floating
            preferencesWindow?.collectionBehavior = .canJoinAllSpaces
            preferencesWindow?.center()
            preferencesWindow?.title = "FloatingBrowser Settings"
            preferencesWindow?.isReleasedWhenClosed = false
            preferencesWindow?.miniaturize(nil)
            preferencesWindow?.zoom(nil)
            preferencesWindow?.contentView = NSHostingView(rootView: preferencesView)
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let toggleURLField = Notification.Name("toogleURLField")
    static let reload = Notification.Name("reload")
    static let historyBack = Notification.Name("historyBack")
    static let historyForward = Notification.Name("historyForward")
    static let urlChanged = Notification.Name("urlChanged")
}
