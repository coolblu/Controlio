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
                MacInput.shared.click(button: e.p.c ?? 0, isDown: (e.p.s ?? 0) == 1)
            case .ax, .gs:
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
