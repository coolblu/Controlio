//
//  GamepadCodes.swift
//  Controlio
//
//  Created by Avis Luong on 11/4/25.
//

import Foundation

public enum GPButton: Int, CaseIterable {
    case a = 10, b = 11, x = 12, y = 13
    case dpadUp = 20, dpadDown = 21, dpadLeft = 22, dpadRight = 23
    case l1 = 30, r1 = 31, r2 = 33
    case start = 40, select = 41

    var settingsKey: String {
        switch self {
        case .a: return "a"
        case .b: return "b"
        case .x: return "x"
        case .y: return "y"
        case .l1: return "l1"
        case .r1: return "r1"
        case .start: return "start"
        case .select: return "select"
        case .dpadUp: return "dpadUp"
        case .dpadDown: return "dpadDown"
        case .dpadLeft: return "dpadLeft"
        case .dpadRight: return "dpadRight"
        case .r2: return "r2"
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .x: return "X"
        case .y: return "Y"
        case .l1: return "L1"
        case .r1: return "R1"
        case .start: return "Start"
        case .select: return "Select"
        case .dpadUp: return "D-Pad Up"
        case .dpadDown: return "D-Pad Down"
        case .dpadLeft: return "D-Pad Left"
        case .dpadRight: return "D-Pad Right"
        case .r2: return "R2"
        }
    }

    static var configurableButtons: [GPButton] {
        [.a, .b, .x, .y, .l1, .r1, .start, .select, .dpadUp, .dpadDown, .dpadLeft, .dpadRight]
    }
}

extension Event {
    static func gpDown(_ b: GPButton, ht: Int? = nil) -> Event { .bt(c: b.rawValue, s: 1, ht: ht) }
    static func gpUp(_ b: GPButton, ht: Int? = nil) -> Event { .bt(c: b.rawValue, s: 0, ht: ht) }
}
