//
//  EventPump.swift
//  ControlioReceiver
//
//  Created by Avis Luong on 10/21/25.
//

import Foundation
import CoreGraphics

final class EventPump {
    static let shared = EventPump()
    
    private let q = DispatchQueue(label: "controlio.rx", qos: .userInteractive)
    private var moveDX: Int32 = 0
    private var moveDY: Int32 = 0
    private var scrlDX: Int32 = 0
    private var scrlDY: Int32 = 0
    
    private var timer: DispatchSourceTimer?
    
    private let pmDeadband: Int32 = 0
    private let scDeadband: Int32 = 0
    
    func start() {
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: q)
        // Send coalesced moves every ~8ms (~120 Hz)
        t.schedule(deadline: .now() + .milliseconds(8),
                   repeating: .milliseconds(8),
                   leeway: .milliseconds(1))
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let mdx = self.moveDX, mdy = self.moveDY
            let sdx = self.scrlDX, sdy = self.scrlDY
            self.moveDX = 0; self.moveDY = 0
            self.scrlDX = 0; self.scrlDY = 0

            if abs(mdx) > self.pmDeadband || abs(mdy) > self.pmDeadband {
                self.applyChunkedMove(dx: Int(mdx), dy: Int(mdy))
            }
            if abs(sdx) > self.scDeadband || abs(sdy) > self.scDeadband {
                MacInput.shared.scrollBy(dx: Int(sdx), dy: Int(sdy))
            }
        }
        
        t.setEventHandler(handler: work)
        t.resume()
        timer = t
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        moveDX = 0; moveDY = 0
        scrlDX = 0; scrlDY = 0
    }
    
    func enqueue(_ e: Event) {
        q.async {
            switch e.t {
            case .pm:
                self.moveDX &+= Int32(e.p.dx ?? 0)
                self.moveDY &+= Int32(e.p.dy ?? 0)

            case .sc:
                self.scrlDX &+= Int32(e.p.dx ?? 0)
                self.scrlDY &+= Int32(e.p.dy ?? 0)

            case .bt:
                // Mouse clicks (0/1) go to MacInput; gamepad (>=10) to KeyboardEmitter
                if let c = e.p.c, c == 0 || c == 1 {
                    MacInput.shared.click(button: c, isDown: (e.p.s ?? 0) == 1)
                } else if let button = GPButton(rawValue: e.p.c ?? -1) {
                    KeyboardEmitter.shared.press(button, isDown: (e.p.s ?? 0) == 1)
                }

            case .ax:
                let x = CGFloat(e.p.k ?? 0) / 1000.0
                let y = CGFloat(e.p.v ?? 0) / 1000.0
                KeyboardEmitter.shared.smoothLeftStick(x: x, y: y)

            case .gs:
                break
            }
        }
    }
    
    private func applyChunkedMove(dx: Int, dy: Int) {
        // tune maxStep if needed, keep small to look smooth
        let maxStep = 12
        let steps = max(1, min(4, max(abs(dx), abs(dy)) / maxStep))
        if steps == 1 {
            MacInput.shared.moveMouseBy(dx: dx, dy: dy)
            return
        }
        let sx = dx / steps, sy = dy / steps
        var remx = dx, remy = dy
        for i in 0..<steps {
            let isLast = i == steps - 1
            let cx = isLast ? remx : sx
            let cy = isLast ? remy : sy
            MacInput.shared.moveMouseBy(dx: cx, dy: cy)
            remx -= sx; remy -= sy
        }
    }
}
