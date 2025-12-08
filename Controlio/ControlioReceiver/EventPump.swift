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
    
    private let axTimeout: CFAbsoluteTime = 0.35
    private let axThreshold: CGFloat = 0.15
    
    private var currentSteering: CGFloat = 0
    private var steeringAccumulator: CGFloat = 0
    
    private var rwDeadzone: CGFloat = 0.40
    private var rwHoldThreshold: CGFloat = 0.90
    private var rwTapRate: CGFloat = 0.05
    private var rwActive = false
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

                // Gamepad buttons
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
                
                if id == 0 {
                    self.lastAX0Time = CFAbsoluteTimeGetCurrent()
                    self.ax0Active = (abs(nx) > self.axThreshold) || (abs(ny) > self.axThreshold)
                    KeyboardEmitter.shared.smoothLeftStick(x: nx, y: ny, threshold: self.axThreshold)
                } else if id == 1 {
                    self.lastAX1Time = CFAbsoluteTimeGetCurrent()
                    self.ax1Active = (abs(nx) > self.axThreshold) || (abs(ny) > self.axThreshold)
                    KeyboardEmitter.shared.smoothRightStickAsArrows(x: nx, y: ny, threshold: self.axThreshold)
                }
                
            case .rw:
                let steer = CGFloat(e.p.c ?? 0) / 1000.0
                self.currentSteering = steer
                self.lastRWTime = CFAbsoluteTimeGetCurrent()
                
                if let dz = e.p.dz { self.rwDeadzone = CGFloat(dz) / 100.0 }
                if let ht = e.p.ht { self.rwHoldThreshold = CGFloat(ht) / 100.0 }
                if let tr = e.p.tr { self.rwTapRate = CGFloat(tr) / 100.0 }
                
                self.rwActive = abs(steer) > self.rwDeadzone
                
            case .gs:
                guard let kind = e.p.k else { return }
                self.handleGesture(kind: kind)
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
            KeyboardEmitter.shared.smoothLeftStick(x: 0, y: 0, threshold: axThreshold)
        }
        if ax1Active && (now - lastAX1Time) > axTimeout {
            ax1Active = false
            KeyboardEmitter.shared.smoothRightStickAsArrows(x: 0, y: 0, threshold: axThreshold)
        }
        if rwActive && (now - lastRWTime) > axTimeout {
            rwActive = false
            currentSteering = 0
            steeringAccumulator = 0
            KeyboardEmitter.shared.steeringRelease()
        }
        
        processRaceWheelSteering()
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
    
    
    private func handleGesture(kind: Int) {
        switch kind {
        case 1:
            MacInput.shared.keyCombo(key: kVK_Tab, modifiers: [.maskControl, .maskShift])
            
        case 2:
            MacInput.shared.keyCombo(key: kVK_Tab, modifiers: [.maskControl])
            
        case 3:
            MacInput.shared.openNotificationCenter()
            
        case 4:
            MacInput.shared.keyCombo(key: kVK_ANSI_Q, modifiers: [.maskCommand])
            
        default:
            break
        }
    }
}