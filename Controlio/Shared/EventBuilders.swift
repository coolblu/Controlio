//
//  EventBuilders.swift
//  Controlio
//
//  Created by Avis Luong on 10/20/25.
//

import Foundation

extension Event {
    static func pm(dx: Int, dy: Int) -> Event {
        Event(t: .pm, p: .init(dx: dx, dy: dy, c: nil, s: nil, k: nil, v: nil, dz: nil, ht: nil, tr: nil))
    }
    static func sc(dx: Int, dy: Int) -> Event {
        Event(t: .sc, p: .init(dx: dx, dy: dy, c: nil, s: nil, k: nil, v: nil, dz: nil, ht: nil, tr: nil))
    }
    static func bt(c: Int, s: Int, ht: Int? = nil) -> Event {
        Event(t: .bt, p: .init(dx: nil, dy: nil, c: c, s: s, k: nil, v: nil, dz: nil, ht: ht, tr: nil))
    }
    static func ax(id: Int, x: Int, y: Int,
                   upKey: Int? = nil, downKey: Int? = nil,
                   leftKey: Int? = nil, rightKey: Int? = nil) -> Event {
        Event(t: .ax, p: .init(dx: upKey, dy: downKey, c: id, s: leftKey, k: x, v: y, dz: nil, ht: rightKey, tr: nil))
    }
    
    static func rw(steer: Int, deadzone: Int, holdThreshold: Int, tapRate: Int) -> Event {
        Event(t: .rw, p: .init(dx: nil, dy: nil, c: steer, s: nil, k: nil, v: nil, dz: deadzone, ht: holdThreshold, tr: tapRate))
    }
    
    // convenience
    static var leftDown: Event  { .bt(c: 0, s: 1) }
    static var leftUp:   Event  { .bt(c: 0, s: 0) }
    static var rightDown: Event { .bt(c: 1, s: 1) }
    static var rightUp:   Event { .bt(c: 1, s: 0) }
}
