//
//  KeyboardEmitter.swift
//  ControlioReceiver
//
//  Created by Evan Weng on 11/11/25.
//

import Foundation
import Carbon.HIToolbox
import CoreGraphics

final class KeyboardEmitter {
    static let shared = KeyboardEmitter()

    private var keyStates: [CGKeyCode: Bool] = [:]

    private func sendKey(_ keyCode: CGKeyCode, down: Bool) {
        guard keyStates[keyCode] != down else { return }
        keyStates[keyCode] = down
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: down) else { return }
        event.post(tap: .cghidEventTap)
    }

    func press(_ button: GPButton, isDown: Bool) {
        guard let keyCode = GamepadKeyMap.mapping[button] else { return }
        sendKey(keyCode, down: isDown)
    }

    func smoothLeftStick(x: CGFloat, y: CGFloat, threshold: CGFloat = 0.15) {
        let left: CGKeyCode = 0
        let right: CGKeyCode = 2
        let up: CGKeyCode = 13
        let down: CGKeyCode = 1

        if x < -threshold {
            sendKey(left, down: true)
            sendKey(right, down: false)
        } else if x > threshold {
            sendKey(right, down: true)
            sendKey(left, down: false)
        } else {
            sendKey(left, down: false)
            sendKey(right, down: false)
        }

        if y > threshold {
            sendKey(down, down: true)
            sendKey(up, down: false)
        } else if y < -threshold {
            sendKey(up, down: true)
            sendKey(down, down: false)
        } else {
            sendKey(up, down: false)
            sendKey(down, down: false)
        }
    }

    func dpad(x: Int, y: Int) {
        arrow(.left,  isDown: x < 0)
        arrow(.right, isDown: x > 0)
        arrow(.up,    isDown: y < 0)
        arrow(.down,  isDown: y > 0)

        if x == 0 {
            arrow(.left,  isDown: false)
            arrow(.right, isDown: false)
        }
        if y == 0 {
            arrow(.up,   isDown: false)
            arrow(.down, isDown: false)
        }
    }
    
    enum ArrowDir { case left, right, up, down }
    
    private func arrowKeyCode(_ dir: ArrowDir) -> CGKeyCode {
        switch dir {
        case .left:  return 123
        case .right: return 124
        case .down:  return 125
        case .up:    return 126
        }
    }
    
    func arrow(_ dir: ArrowDir, isDown: Bool) {
        sendKey(arrowKeyCode(dir), down: isDown)
    }

    func smoothRightStickAsArrows(x: CGFloat, y: CGFloat, threshold: CGFloat = 0.15) {
        if x < -threshold {
            arrow(.left, isDown: true)
            arrow(.right, isDown: false)
        } else if x > threshold {
            arrow(.right, isDown: true)
            arrow(.left, isDown: false)
        } else {
            arrow(.left, isDown: false)
            arrow(.right, isDown: false)
        }

        if y > threshold {
            arrow(.down, isDown: true)
            arrow(.up,   isDown: false)
        } else if y < -threshold {
            arrow(.up,   isDown: true)
            arrow(.down, isDown: false)
        } else {
            arrow(.up,   isDown: false)
            arrow(.down, isDown: false)
        }
    }
}

enum GamepadKeyMap {
    static let mapping: [GPButton: CGKeyCode] = [
        // ABXY
        .a: 49, // Space
        .b: 11, // B
        .x: 7, // X
        .y: 16, // Y
        // Shoulders
        .l1: 12, // Q
        .r1: 14, // E
        // Start/Select
        .select: 51, // Delete
        .start: 53 // Escape
    ]
}

