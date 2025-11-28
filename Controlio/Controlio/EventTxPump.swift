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
    private var latestAxes: [Int: (x: Int, y: Int)] = [:]
    private var buffer = Data()
    private var timer: DispatchSourceTimer?
    private weak var mc: MCManager?

    func start(mc: MCManager) {
        self.mc = mc
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: q)
        t.schedule(deadline: .now() + .milliseconds(3), repeating: .milliseconds(3))
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
            case .ax:
                let id = e.p.c ?? 0
                self.latestAxes[id] = (e.p.k ?? 0, e.p.v ?? 0)
            default:
                // one-off events get appended and will ride next tick
                self.buffer.append(encodeLine(e))
                self.flush() // push buttons/gestures promptly
            }
        }
    }

    private func flush() {
        guard let mc = mc else { return }
        var reliableOut = Data()
        var unreliableOut = Data()

        if moveDX != 0 || moveDY != 0 {
            unreliableOut.append(encodeLine(.pm(dx: moveDX, dy: moveDY)))
            moveDX = 0; moveDY = 0
        }
        if scrollDX != 0 || scrollDY != 0 {
            unreliableOut.append(encodeLine(.sc(dx: scrollDX, dy: scrollDY)))
            scrollDX = 0; scrollDY = 0
        }
        if !buffer.isEmpty {
            reliableOut.append(buffer)
            buffer.removeAll(keepingCapacity: true)
        }
        if !latestAxes.isEmpty {
            for (id, xy) in latestAxes {
                unreliableOut.append(encodeLine(.ax(id: id, x: xy.x, y: xy.y)))
            }
            latestAxes.removeAll(keepingCapacity: true)
        }
        if !unreliableOut.isEmpty { mc.sendRaw(unreliableOut, reliable: false) }
        if !reliableOut.isEmpty { mc.sendRaw(reliableOut, reliable: true) }
    }
}
