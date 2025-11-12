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
                    KeyboardEmitter.shared.smoothLeftStick(x: nx, y: ny)
                } else if id == 1 {
                    KeyboardEmitter.shared.smoothRightStickAsArrows(x: nx, y: ny)
                }

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
    }
}
