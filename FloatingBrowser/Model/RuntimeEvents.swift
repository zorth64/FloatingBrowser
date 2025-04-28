//
//  RuntimeEvents.swift
//  FloatingBrowser
//
//  Created by zorth64 on 26/04/25.
//  Copyright © 2025 Andrew Finke. All rights reserved.
//

import Combine
import Foundation

enum RuntimeEvent {
    case loading
    case launching
    case closing
}

class RuntimeEvents {
    private let subject = CurrentValueSubject<RuntimeEvent, Never>(.loading)
    
    func send(_ event: RuntimeEvent) {
        subject.send(event)
    }
    
    func events() -> AnyPublisher<RuntimeEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}
