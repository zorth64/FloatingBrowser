//
//  DominantColor.swift
//  FloatingBrowser
//
//  Created by zorth64 on 22/12/23.
//  Copyright © 2023 Andrew Finke. All rights reserved.
//

import Foundation
import SwiftUI

struct DominantColor: Codable, Identifiable, Equatable {
    let id: String
    let host: String
    let color: MyColor
}

extension DominantColor {
    static func ==(lhs: DominantColor, rhs: DominantColor) -> Bool {
        return lhs.id == rhs.id
    }
}

extension URL {
    func asDominantColor(color: Color) -> DominantColor {
        DominantColor(
            id: UUID().uuidString,
            host: "\(host() ?? "")\(pathComponents.first ?? "")",
            color: MyColor(color: color)
        )
    }
}

struct MyColor: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(color: Color) {
        self.red = NSColor(color).redComponent
        self.green = NSColor(color).greenComponent
        self.blue = NSColor(color).blueComponent
    }

    var getColor: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    var asNSColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension MyColor {
    func isEqual(color: NSColor) -> Bool {
        return red == color.redComponent
            && green == color.greenComponent
            && blue == color.blueComponent
    }
}
