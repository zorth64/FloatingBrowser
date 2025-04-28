//
//  Window.swift
//  FloatingBrowser
//
//  Created by zorth64 on 26/04/25.
//  Copyright © 2025 Andrew Finke. All rights reserved.
//

import Cocoa
import Combine

class Window: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
    }
}

class FloatingBrowserWindow: Window, NSWindowDelegate {
    @Inject private var appState: AppState
    @Inject private var runtimeEvents: RuntimeEvents
    
    private var disposables = Set<AnyCancellable>()
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
    
    func setup() {
        styleMask.insert(.fullSizeContentView)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        alphaValue = 1.0
        isReleasedWhenClosed = true
        backgroundColor = NSColor.black.withAlphaComponent(0.0001)
        delegate = self
        setWindowPosition()
        bindFloating()
    }
    
    func windowWillClose(_ notification: Notification) {
        runtimeEvents.send(.closing)
    }
    
    func windowDidMove(_ notification: Notification) {
        if (ObjectIdentifier(self) == appState.firstWindowId) {
            let frame = self.frame
            appState.windowPosition = CGPoint(x: frame.origin.x, y: frame.origin.y)
        }
    }
    
    private func setWindowPosition() {
        if (appState.windowPosition.x == 0 && appState.windowPosition.y == 0) {
            center()
        } else {
            setFrameOrigin(appState.windowPosition)
        }
    }
    
    private func bindFloating() {
        appState.$shouldWindowFloat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldWindowFloat in
                self?.level = shouldWindowFloat ? .floating : .normal
            }
            .store(in: &disposables)
    }
}
