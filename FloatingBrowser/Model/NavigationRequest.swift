//
//  NavigationRequest.swift
//  FloatingBrowser
//
//  Created by zorth64 on 20/12/23.
//  Copyright © 2023 Andrew Finke. All rights reserved.
//

import Foundation

enum NavigationRequest {
    case reload
    case html(text: String, baseURL: URL?)
    case urlString(urlString: String)
    case url(url: URL)
    case search(input: String)
    case back
    case forward
}

