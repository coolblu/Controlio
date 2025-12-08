//
//  EventPump.swift
//  ControlioReceiver
//
//  Created by Avis Luong on 10/21/25.
//

// EventPump.swift (macOS)
import Foundation
import CoreGraphics

final class EventPump {
    static let shared = EventPump()
    private let q = DispatchQueue(label: "controlio.rx", qos: .userInteractive)

    private var accDX = 0, accDY = 0
    private var accSX = 0, accSY = 0
    
    private var lastAX0Time: CFAbsoluteTime = 0
    private var lastAX1Time: CFAbsoluteTime = 0
    private var ax0Active = false
    private var ax1Active = false
    
    private var ax0Keys: (up: CGKeyCode, down: CGKeyCode, left: CGKeyCode, right: CGKeyCode) = (13, 1, 0, 2)
    private var ax1Keys: (up: CGKeyCode, down: CGKeyCode, left: CGKeyCode, right: CGKeyCode) = (126, 125, 123, 124)
    
    private let axTimeout: CFAbsoluteTime = 0.35
    private let axThreshold: CGFloat = 0.15
    
    private var currentSteering: CGFloat = 0
    private var steeringAccumulator: CGFloat = 0
    
    private var rwDeadzone: CGFloat = 0.40
    private var rwHoldThreshold: CGFloat = 0.90
    private var rwTapRate: CGFloat = 0.05
    private var rwActive = false
    private var rwEverUsed = false
    private var lastRWTime: CFAbsoluteTime = 0

    private var timer: DispatchSourceTimer?

    init() {
        let t = DispatchSource.makeTimerSource(queue: q)
        t.schedule(deadline: .now() + .milliseconds(4), repeating: .milliseconds(4)) // ~250 Hz
        t.setEventHandler { [weak self] in self?.drain() }
        t.resume()
        timer = t
    }

    func enqueue(_ e: Event) {
        q.async {
            switch e.t {
            case .pm:
                self.accDX += (e.p.dx ?? 0)
                self.accDY += (e.p.dy ?? 0)

            case .sc:
                self.accSX += (e.p.dx ?? 0)
                self.accSY += (e.p.dy ?? 0)

            case .bt:
                guard let code = e.p.c, let s = e.p.s else { return }
                let isDown = (s == 1)

                if code == 0 || code == 1 {
                    MacInput.shared.click(button: code, isDown: isDown)
                    return
                }

                if let keyHint = e.p.ht {
                    KeyboardEmitter.shared.pressKey(CGKeyCode(keyHint), isDown: isDown)
                    return
                }

                if let gp = GPButton(rawValue: code) {
                    switch gp {
                    case .dpadLeft:  KeyboardEmitter.shared.arrow(.left,  isDown: isDown)
                    case .dpadRight: KeyboardEmitter.shared.arrow(.right, isDown: isDown)
                    case .dpadUp:    KeyboardEmitter.shared.arrow(.up,    isDown: isDown)
                    case .dpadDown:  KeyboardEmitter.shared.arrow(.down,  isDown: isDown)
                    default:
                        KeyboardEmitter.shared.press(gp, isDown: isDown)
                    }
                }
                
            case .ax:
                let id = e.p.c ?? -1
                let nx = CGFloat(e.p.k ?? 0) / 1000.0
                let ny = CGFloat(e.p.v ?? 0) / 1000.0
                
                let upKey = e.p.dx.map { CGKeyCode($0) }
                let downKey = e.p.dy.map { CGKeyCode($0) }
                let leftKey = e.p.s.map { CGKeyCode($0) }
                let rightKey = e.p.ht.map { CGKeyCode($0) }
                
                if id == 0 {
                    self.lastAX0Time = CFAbsoluteTimeGetCurrent()
                    self.ax0Active = (abs(nx) > self.axThreshold) || (abs(ny) > self.axThreshold)
                    let keys = (up: upKey ?? 13, down: downKey ?? 1, left: leftKey ?? 0, right: rightKey ?? 2)
                    self.ax0Keys = keys
                    KeyboardEmitter.shared.smoothLeftStick(
                        x: nx, y: ny, threshold: self.axThreshold,
                        leftKey: keys.left, rightKey: keys.right,
                        upKey: keys.up, downKey: keys.down
                    )
                } else if id == 1 {
                    self.lastAX1Time = CFAbsoluteTimeGetCurrent()
                    self.ax1Active = (abs(nx) > self.axThreshold) || (abs(ny) > self.axThreshold)
                    let keys = (up: upKey ?? 126, down: downKey ?? 125, left: leftKey ?? 123, right: rightKey ?? 124)
                    self.ax1Keys = keys
                    KeyboardEmitter.shared.smoothRightStickAsArrows(
                        x: nx, y: ny, threshold: self.axThreshold,
                        leftKey: keys.left, rightKey: keys.right,
                        upKey: keys.up, downKey: keys.down
                    )
                }
                
            case .rw:
                let steer = CGFloat(e.p.c ?? 0) / 1000.0
                self.currentSteering = steer
                self.lastRWTime = CFAbsoluteTimeGetCurrent()
                self.rwEverUsed = true
                
                if let dz = e.p.dz { self.rwDeadzone = CGFloat(dz) / 100.0 }
                if let ht = e.p.ht { self.rwHoldThreshold = CGFloat(ht) / 100.0 }
                if let tr = e.p.tr { self.rwTapRate = CGFloat(tr) / 100.0 }
                
                self.rwActive = abs(steer) > self.rwDeadzone
                
            case .gs:
                break
            }
        }
    }
    
    private func drain() {
        let dx = accDX, dy = accDY
        if dx != 0 || dy != 0 {
            accDX = 0; accDY = 0
            MacInput.shared.moveMouseBy(dx: dx, dy: dy)
        }

        let sx = accSX, sy = accSY
        if sx != 0 || sy != 0 {
            accSX = 0; accSY = 0
            MacInput.shared.scrollBy(dx: sx, dy: sy)
        }

        let now = CFAbsoluteTimeGetCurrent()

        if ax0Active && (now - lastAX0Time) > axTimeout {
            ax0Active = false
            KeyboardEmitter.shared.smoothLeftStick(
                x: 0, y: 0, threshold: axThreshold,
                leftKey: ax0Keys.left, rightKey: ax0Keys.right,
                upKey: ax0Keys.up, downKey: ax0Keys.down
            )
        }
        if ax1Active && (now - lastAX1Time) > axTimeout {
            ax1Active = false
            KeyboardEmitter.shared.smoothRightStickAsArrows(
                x: 0, y: 0, threshold: axThreshold,
                leftKey: ax1Keys.left, rightKey: ax1Keys.right,
                upKey: ax1Keys.up, downKey: ax1Keys.down
            )
        }
        if rwActive && (now - lastRWTime) > axTimeout {
            rwActive = false
            currentSteering = 0
            steeringAccumulator = 0
            KeyboardEmitter.shared.steeringRelease()
        }
        
        if rwEverUsed {
            processRaceWheelSteering()
        }
    }
    
    private func processRaceWheelSteering() {
        let intensity = abs(currentSteering)
        
        if intensity < rwDeadzone {
            KeyboardEmitter.shared.steeringRelease()
            steeringAccumulator = 0
            return
        }
        
        let normalizedIntensity = (intensity - rwDeadzone) / (1.0 - rwDeadzone)
        let goingLeft = currentSteering < 0
        
        if normalizedIntensity > rwHoldThreshold {
            KeyboardEmitter.shared.steeringHold(left: goingLeft)
            steeringAccumulator = 0
            return
        }
        
        steeringAccumulator += normalizedIntensity * rwTapRate
        
        if steeringAccumulator >= 1.0 {
            KeyboardEmitter.shared.steeringTap(left: goingLeft)
            steeringAccumulator = 0
        } else {
            KeyboardEmitter.shared.steeringRelease()
        }
    }
}