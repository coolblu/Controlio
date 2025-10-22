//
//  EventBuilders.swift
//  Controlio
//
//  Created by Avis Luong on 10/20/25.
//

import Foundation

extension Event {
    static func pm(dx: Int, dy: Int) -> Event {
        Event(t: .pm, p: .init(dx: dx, dy: dy, c: nil, s: nil, k: nil, v: nil))
    }
    static func sc(dx: Int, dy: Int) -> Event {
        Event(t: .sc, p: .init(dx: dx, dy: dy, c: nil, s: nil, k: nil, v: nil))
    }
    static func bt(c: Int, s: Int) -> Event {
        Event(t: .bt, p: .init(dx: nil, dy: nil, c: c, s: s, k: nil, v: nil))
    }
    // convenience
    static var leftDown: Event  { .bt(c: 0, s: 1) }
    static var leftUp:   Event  { .bt(c: 0, s: 0) }
    static var rightDown: Event { .bt(c: 1, s: 1) }
    static var rightUp:   Event { .bt(c: 1, s: 0) }
}
