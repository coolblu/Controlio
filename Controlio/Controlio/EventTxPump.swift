//
//  EventTxPump.swift
//  Controlio
//
//  Created by Avis Luong on 11/11/25.
//

import Foundation

final class EventTxPump {
    static let shared = EventTxPump()

    private let q = DispatchQueue(label: "controlio.tx", qos: .userInteractive)
    private var moveDX = 0, moveDY = 0
    private var scrollDX = 0, scrollDY = 0
    private var buffer = Data()
    private var timer: DispatchSourceTimer?
    private weak var mc: MCManager?

    func start(mc: MCManager) {
        self.mc = mc
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: q)
        t.schedule(deadline: .now() + .milliseconds(4), repeating: .milliseconds(4))
        t.setEventHandler { [weak self] in self?.flush() }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func queue(_ e: Event) {
        q.async {
            switch e.t {
            case .pm:
                self.moveDX += e.p.dx ?? 0
                self.moveDY += e.p.dy ?? 0
            case .sc:
                self.scrollDX += e.p.dx ?? 0
                self.scrollDY += e.p.dy ?? 0
            default:
                // one-off events get appended and will ride next tick
                self.buffer.append(encodeLine(e))
            }
        }
    }

    private func flush() {
        guard let mc = mc else { return }
        var burstUnreliable = Data()
        var burstReliable   = Data()

        if moveDX != 0 || moveDY != 0 {
            burstUnreliable.append(encodeLine(.pm(dx: moveDX, dy: moveDY)))
            moveDX = 0; moveDY = 0
        }
        if scrollDX != 0 || scrollDY != 0 {
            burstUnreliable.append(encodeLine(.sc(dx: scrollDX, dy: scrollDY)))
            scrollDX = 0; scrollDY = 0
        }
        if !buffer.isEmpty {
            burstReliable.append(buffer)
            buffer.removeAll(keepingCapacity: true)
        }
        if !burstUnreliable.isEmpty {
            mc.sendRaw(burstUnreliable, reliable: false)
        }
        if !burstReliable.isEmpty {
            mc.sendRaw(burstReliable, reliable: true)
        }
    }
}
