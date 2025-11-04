//
//  GamepadCodes.swift
//  Controlio
//
//  Created by Avis Luong on 11/4/25.
//

import Foundation

public enum GPButton: Int {
    case a = 10, b = 11, x = 12, y = 13
    case dpadUp = 20, dpadDown = 21, dpadLeft = 22, dpadRight = 23
    case l1 = 30, r1 = 31, r2 = 33
    case start = 40, select = 41
}

extension Event {
    static func gpDown(_ b: GPButton) -> Event { .bt(c: b.rawValue, s:1) }
    static func gpUp(_ b: GPButton) -> Event { .bt(c: b.rawValue, s: 0) }
}
