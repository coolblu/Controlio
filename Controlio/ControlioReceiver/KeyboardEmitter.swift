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
        let left: CGKeyCode = 123
        let right: CGKeyCode = 124
        let down: CGKeyCode = 125
        let up: CGKeyCode = 126

        sendKey(left, down: x < 0)
        sendKey(right, down: x > 0)
        sendKey(up, down: y < 0)
        sendKey(down, down: y > 0)

        if x == 0 {
            sendKey(left, down: false)
            sendKey(right, down: false)
        }
        if y == 0 {
            sendKey(up, down: false)
            sendKey(down, down: false)
        }
    }
}

enum GamepadKeyMap {
    static let mapping: [GPButton: CGKeyCode] = [
        .a: 49,
        .b: 11,
        .x: 7,
        .y: 16,
        .l1: 12,
        .r1: 14,
        .select: 51,
        .start: 53
    ]
}
