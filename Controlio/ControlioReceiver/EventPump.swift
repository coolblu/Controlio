//
//  EventPump.swift
//  ControlioReceiver
//
//  Created by Avis Luong on 10/21/25.
//

import Foundation

final class EventPump {
    static let shared = EventPump()
    
    private let q = DispatchQueue(label: "controlio.rx", qos: .userInteractive)
    private var moveDX = 0
    private var moveDY = 0
    private var timer: DispatchSourceTimer?
    
    func start() {
        if timer != nil { return }
        let t = DispatchSource.makeTimerSource(queue: q)
        // Send coalesced moves every ~8ms (~120 Hz)
        t.schedule(deadline: .now() + .milliseconds(8), repeating: .milliseconds(1))
        t.setEventHandler { [weak self] in
            guard let self = self else { return }
            let dx = self.moveDX; let dy = self.moveDY
            if dx != 0 || dy != 0 {
                self.moveDX = 0; self.moveDY = 0
                MacInput.shared.moveMouseBy(dx: dx, dy: dy)
            }
        }
        t.resume()
        timer = t
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
    
    func enqueue(_ e: Event) {
        q.async {
            switch e.t {
            case .pm:
                self.moveDX += e.p.dx ?? 0
                self.moveDY += e.p.dy ?? 0
            case .sc:
                MacInput.shared.scrollBy(dx: e.p.dx ?? 0, dy: e.p.dy ?? 0)
            case .bt:
                MacInput.shared.click(button: e.p.c ?? 0, isDown: (e.p.s ?? 0) == 1)
            case .gs:
                break
            }
        }
    }
}
