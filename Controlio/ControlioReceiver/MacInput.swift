//
//  MacInput.swift
//  ControlioReceiver
//
//  Created by Avis Luong on 10/21/25.
//

import Cocoa
import ApplicationServices

final class MacInput {
    static let shared = MacInput()
    
    private var isLeftDown = false
    
    func handle(_ e: Event) {
        switch e.t {
        case .pm:
            let dx = e.p.dx ?? 0
            let dy = e.p.dy ?? 0
            moveMouseBy(dx: dx, dy: dy)
        case .sc:
            let dx = e.p.dx ?? 0
            let dy = e.p.dy ?? 0
            scrollBy(dx: dx, dy: dy)
        case .bt:
            let c = e.p.c ?? 0 // 0 left, 1 right
            let s = e.p.s ?? 0 // 0 up, 1 down
            click(button: c, isDown: s == 1)
        case .ax:
            let id = e.p.c ?? -1
            let x  = (e.p.k ?? 0)
            let y  = (e.p.v ?? 0)
            print("ax:", "id:", id, "x:", x, "y:", y)
        case .gs:
            // reserved; ignore for now
            break
        }
    }
    
    private func currentMouse() -> CGPoint {
        let loc = CGEvent(source: nil)?.location ?? .zero
        return loc
    }
    
    private func clampToMainDisplay(_ p: CGPoint) -> CGPoint {
        let bounds = CGDisplayBounds(CGMainDisplayID())
        let minX = CGFloat(bounds.minX), maxX = CGFloat(bounds.maxX - 1)
        let minY = CGFloat(bounds.minY), maxY = CGFloat(bounds.maxY - 1)
        return CGPoint(x: min(max(p.x, minX), maxX),
                       y: min(max(p.y, minY), maxY))
    }
    
    func moveMouseBy(dx: Int, dy: Int) {
        let cur = currentMouse()
        let newPoint = clampToMainDisplay(CGPoint(x: cur.x + CGFloat(dx),
                                                  y: cur.y - CGFloat(dy))) // invert Y
        // Use appropriate event type depending on button state for smoother drag
        let type: CGEventType = isLeftDown ? .leftMouseDragged : .mouseMoved
        let evt = CGEvent(mouseEventSource: nil, mouseType: type,
                          mouseCursorPosition: newPoint, mouseButton: .left)
        evt?.post(tap: .cghidEventTap)
    }
    
    func click(button: Int, isDown: Bool) {
        let cur = currentMouse()
        let cgButton: CGMouseButton = (button == 0) ? .left : .right
        let type: CGEventType = {
            if button == 0 { return isDown ? .leftMouseDown : .leftMouseUp }
            else { return isDown ? .rightMouseDown : .rightMouseUp }
        }()

        if button == 0 { isLeftDown = isDown }

        let evt = CGEvent(mouseEventSource: nil, mouseType: type,
                          mouseCursorPosition: cur, mouseButton: cgButton)
        evt?.post(tap: .cghidEventTap)	
    }
    
    func scrollBy(dx: Int, dy: Int) {
        let evt = CGEvent(scrollWheelEvent2Source: nil,
                          units: .pixel,
                          wheelCount: 2,
                          wheel1: Int32(-dy),   // vertical
                          wheel2: Int32(dx),    // horizontal
                          wheel3: 0)
        evt?.post(tap: .cghidEventTap)
    }
}
