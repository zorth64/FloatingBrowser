//
//  WindowController.swift
//  FloatingBrowser
//
//  Created by zorth64 on 19/12/23.
//  Copyright © 2023 Andrew Finke. All rights reserved.
//

import Cocoa
import SwiftUI

class WindowController: NSWindowController {
    
    init(window: FloatingBrowserWindow) {
        super.init(window: window)
        let contentView = ContentView()
            .edgesIgnoringSafeArea(.top)
            .environmentObject(AppState())

        window.contentView = NSHostingView(rootView: contentView)
        window.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
