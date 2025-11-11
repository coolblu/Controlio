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

    func enqueue(_ e: Event) {
        q.async {
            switch e.t {
            case .pm:
                MacInput.shared.moveMouseBy(dx: e.p.dx ?? 0, dy: e.p.dy ?? 0)

            case .sc:
                MacInput.shared.scrollBy(dx: e.p.dx ?? 0, dy: e.p.dy ?? 0)

            case .bt:
                if let c = e.p.c, c == 0 || c == 1 {
                    MacInput.shared.click(button: c, isDown: (e.p.s ?? 0) == 1)
                } else if let b = GPButton(rawValue: e.p.c ?? -1) {
                    KeyboardEmitter.shared.press(b, isDown: (e.p.s ?? 0) == 1)
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
}
