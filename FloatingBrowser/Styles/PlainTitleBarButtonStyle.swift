//
//  PlainTitleBarButtonStyle.swift
//  FloatingBrowser
//
//  Created by zorth64 on 18/11/24.
//  Copyright © 2024 Andrew Finke. All rights reserved.
//

import SwiftUI

struct PlainTitleBarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.controlActiveState) var activeState

    var color: Color
    
    @State private var isHovering: Bool = false
    @Binding var isFocusedWindow: Bool
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .frame(width: 20, height: 20, alignment: .center)
            .fontWeight(.regular)
            .foregroundStyle(
                isEnabled ?
                isFocusedWindow && activeState == .key ? color : color.opacity(0.65) :
                    activeState == .key ? color.opacity(0.32) : color.opacity(0.28)
            )
            .background(
                isHovering ?
                    color.opacity(0.15) :
                    configuration.isPressed ?
                        color.opacity(0.25) : Color.clear
            )
            .cornerRadius(3)
            .contentShape(Rectangle())
            .onHover { hovered in
                isHovering = hovered
            }
    }
    
}
