//
//  KeyboardEmitter.swift
//  ControlioReceiver
//
//  Created by Evan Weng on 11/11/25.
//

import Foundation
import Carbon.HIToolbox
import CoreGraphics
import os

final class KeyboardEmitter {
    static let shared = KeyboardEmitter()

    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private let debugKeyEvents = ProcessInfo.processInfo.environment["CONTROLIO_DEBUG_KEYS"] == "1"
    
    private let repeatInitialDelay: TimeInterval = 0.20
    private let repeatHz: Double = 30.0
    private var repeatInterval: TimeInterval { 1.0 / repeatHz }
    
    private var lock = os_unfair_lock_s()
    private var keyStates: [CGKeyCode: Bool] = [:]
    private var repeatTimers: [CGKeyCode: DispatchSourceTimer] = [:]
    private var repeatTokens: [CGKeyCode: UInt64] = [:]
    
    private let timerQueue = DispatchQueue(label: "controlio.keyrepeat.timers", qos: .userInteractive)
    
    private func postKey(_ keyCode: CGKeyCode, down: Bool, isRepeat: Bool) {
        guard let ev = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: down) else { return }
        ev.flags = [] // ensure no stale modifier flags (prevent accidental Control/Fn combos)
        ev.setIntegerValueField(.keyboardEventAutorepeat, value: isRepeat ? 1 : 0)
        if debugKeyEvents {
            print("KeyEmitter: keyCode=\(keyCode) down=\(down) repeat=\(isRepeat) flags=\(ev.flags.rawValue)")
        }
        ev.post(tap: .cghidEventTap)
    }
    
    private func startRepeating(_ keyCode: CGKeyCode) {
        stopRepeating(keyCode)

        let token: UInt64 = {
            os_unfair_lock_lock(&lock)
            let next = (repeatTokens[keyCode] ?? 0) &+ 1
            repeatTokens[keyCode] = next
            os_unfair_lock_unlock(&lock)
            return next
        }()

        let t = DispatchSource.makeTimerSource(queue: timerQueue)
        t.schedule(deadline: .now() + repeatInitialDelay, repeating: repeatInterval)
        t.setEventHandler { [weak self] in
            guard let self = self else { return }
            // Check state & token atomically
            var shouldRepeat = false
            os_unfair_lock_lock(&self.lock)
            if self.keyStates[keyCode] == true, self.repeatTokens[keyCode] == token {
                shouldRepeat = true
            }
            os_unfair_lock_unlock(&self.lock)

            if shouldRepeat {
                self.postKey(keyCode, down: true, isRepeat: true)
            }
        }
        t.resume()

        os_unfair_lock_lock(&lock)
        repeatTimers[keyCode] = t
        os_unfair_lock_unlock(&lock)
    }

    private func stopRepeating(_ keyCode: CGKeyCode) {
        var timer: DispatchSourceTimer?
        os_unfair_lock_lock(&lock)
        repeatTokens[keyCode] = (repeatTokens[keyCode] ?? 0) &+ 1
        if let t = repeatTimers.removeValue(forKey: keyCode) {
            timer = t
        }
        os_unfair_lock_unlock(&lock)
        timer?.cancel()
    }
    
    private func sendKey(_ keyCode: CGKeyCode, down: Bool, repeatable: Bool = true) {
        var transitionNeeded = false
        var goingDown = false

        os_unfair_lock_lock(&lock)
        let wasDown = (keyStates[keyCode] ?? false)

        if down {
            if !wasDown {
                keyStates[keyCode] = true
                transitionNeeded = true
                goingDown = true
            }
        } else {
            if wasDown {
                keyStates[keyCode] = false
                transitionNeeded = true
                goingDown = false
            }
        }
        os_unfair_lock_unlock(&lock)

        if transitionNeeded {
            if goingDown {
                postKey(keyCode, down: true, isRepeat: false)
                if repeatable { startRepeating(keyCode) }
            } else {
                stopRepeating(keyCode)
                postKey(keyCode, down: false, isRepeat: false)
            }
        }
    }

    func press(_ button: GPButton, isDown: Bool) {
        guard let keyCode = GamepadKeyMap.mapping[button] else { return }
        let repeatable = GamepadKeyMap.isRepeatable(button)
        sendKey(keyCode, down: isDown, repeatable: repeatable)
    }

    func smoothLeftStick(x: CGFloat, y: CGFloat, threshold: CGFloat = 0.15) {
        let left: CGKeyCode  = 0
        let right: CGKeyCode = 2
        let up: CGKeyCode    = 13
        let down: CGKeyCode  = 1

        // Horizontal
        let leftOn  = x < -threshold
        let rightOn = x >  threshold
        sendKey(left,  down: leftOn,  repeatable: false)
        sendKey(right, down: rightOn, repeatable: false)
        if !leftOn && !rightOn {
            sendKey(left,  down: false, repeatable: false)
            sendKey(right, down: false, repeatable: false)
        }

        let downOn = y >  threshold
        let upOn   = y < -threshold
        sendKey(down, down: downOn, repeatable: false)
        sendKey(up,   down: upOn,   repeatable: false)
        if !upOn && !downOn {
            sendKey(up,   down: false, repeatable: false)
            sendKey(down, down: false, repeatable: false)
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
        sendKey(arrowKeyCode(dir), down: isDown, repeatable: false)
    }

    func smoothRightStickAsArrows(x: CGFloat, y: CGFloat, threshold: CGFloat = 0.15) {
        let leftOn  = x < -threshold
        let rightOn = x >  threshold
        arrow(.left,  isDown: leftOn)
        arrow(.right, isDown: rightOn)
        if !leftOn && !rightOn {
            arrow(.left,  isDown: false)
            arrow(.right, isDown: false)
        }

        let downOn = y >  threshold
        let upOn   = y < -threshold
        arrow(.down, isDown: downOn)
        arrow(.up,   isDown: upOn)
        if !upOn && !downOn {
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
    
    static func isRepeatable(_ b: GPButton) -> Bool {
        switch b {
        case .start, .select:
            return false
        default:
            return true
        }
    }
}

