//
//  TouchPadSurface.swift
//  Controlio
//
//  Created by Avis Luong on 10/20/25.
//

import SwiftUI
import CoreGraphics

struct TouchPadSurface: UIViewRepresentable {
    var pointerMultiplier: Double
    var scrollMultiplier: Double
    var invertScroll: Bool
    var onPointer: (Int, Int) -> Void
    var onScroll: (Int, Int) -> Void
    var onLeftDown: () -> Void
    var onLeftUp: () -> Void
    var onLeftClick: () -> Void
    var onRightClick: () -> Void
    
    func makeUIView(context: Context) -> PadView {
        let v = PadView()
        v.pointerMultiplier = pointerMultiplier
        v.scrollMultiplier = scrollMultiplier
        v.invertScroll = invertScroll
        v.onPointer = onPointer
        v.onScroll = onScroll
        v.onLeftDown = onLeftDown
        v.onLeftUp = onLeftUp
        v.onLeftClick = onLeftClick
        v.onRightClick = onRightClick
        return v
    }

    func updateUIView(_ uiView: PadView, context: Context) {
        uiView.pointerMultiplier = pointerMultiplier
        uiView.scrollMultiplier = scrollMultiplier
        uiView.invertScroll = invertScroll
        
        uiView.onPointer = onPointer
        uiView.onScroll = onScroll
        uiView.onLeftDown = onLeftDown
        uiView.onLeftUp = onLeftUp
        uiView.onLeftClick = onLeftClick
        uiView.onRightClick = onRightClick
    }
}

final class PadView: UIView, UIGestureRecognizerDelegate {
    var pointerMultiplier: Double = 1.0
    var scrollMultiplier: Double  = 1.0

    var onPointer: (Int, Int) -> Void = { _, _ in }
    var onScroll: (Int, Int) -> Void = { _, _ in }
    var onLeftDown: () -> Void = {}
    var onLeftUp: () -> Void = {}
    var onLeftClick: () -> Void = {}
    var onRightClick: () -> Void = {}

    private var pxRemX = 0.0, pxRemY = 0.0
    private var scRemX = 0.0, scRemY = 0.0
    
    private var lastOne: CGPoint?
    private var lastTwoCenter: CGPoint?
    
    var invertScroll: Bool = false
    
    private lazy var twoFingerTap: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(didTwoFingerTap(_:)))
        g.numberOfTouchesRequired = 2
        g.numberOfTapsRequired = 1
        g.cancelsTouchesInView = false
        g.delaysTouchesBegan = false
        g.delegate = self
        return g
    }()
    
    private lazy var dragHold: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(didDragHold(_:)))
        g.minimumPressDuration = 0.10
        g.numberOfTapsRequired = 2
        g.cancelsTouchesInView = false
        g.delaysTouchesBegan = false
        g.delegate = self
        return g
    }()

    private lazy var tap: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        g.numberOfTapsRequired = 1
        g.delegate = self
        return g
    }()

    private lazy var longPress: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        g.minimumPressDuration = 0.20
        g.cancelsTouchesInView = false
        g.delaysTouchesBegan = false
        g.delegate = self
        return g
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear

        addGestureRecognizer(tap)
        addGestureRecognizer(longPress)
        addGestureRecognizer(dragHold)
        addGestureRecognizer(twoFingerTap)

        tap.require(toFail: twoFingerTap)
        tap.require(toFail: dragHold)
        longPress.require(toFail: dragHold)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    @objc private func didTap(_ g: UITapGestureRecognizer) {
        if g.state == .ended { onLeftClick() }
    }

    @objc private func didLongPress(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began: onLeftDown()
        case .ended, .cancelled, .failed: onLeftUp()
        default: break
        }
    }
    
    @objc private func didTwoFingerTap(_ g: UITapGestureRecognizer) {
        if g.state == .ended { onRightClick() }
    }
    
    @objc private func didDragHold(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began: onLeftDown()
        case .changed: break
        case .ended, .cancelled, .failed: onLeftUp()
        default: break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let e = event else { return }
        let all = Array(touches)
        if all.count == 1 {
            lastOne = all[0].location(in: self)
        } else {
            lastTwoCenter = center(of: all.map { $0.location(in: self) })
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let e = event else { return }
        // Expand to coalesced samples for higher frequency
        let expanded: [UITouch] = touches.flatMap { e.coalescedTouches(for: $0) ?? [$0] }

        if touchCount(in: e) >= 2 {
            let current = currentTwoCenter(from: e)
            if let prev = lastTwoCenter {
                let dx = Double(current.x - prev.x) * scrollMultiplier
                let dy = Double(current.y - prev.y) * scrollMultiplier
                emitScroll(dx: dx, dy: dy)
            }
            lastTwoCenter = current
        } else {
            // One-finger pointer keeps the coalesced samples for smoothness
            for t in expanded {
                let p = t.location(in: self)
                let prev = lastOne ?? p
                let dx = Double(p.x - prev.x) * pointerMultiplier
                let dy = Double(p.y - prev.y) * pointerMultiplier
                emitPointer(dx: dx, dy: dy)
                lastOne = p
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchCount(in: event) <= 1 { lastTwoCenter = nil }
        lastOne = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastOne = nil
        lastTwoCenter = nil
        pxRemX = 0; pxRemY = 0
        scRemX = 0; scRemY = 0
    }
    
    private let FP_SCALE = 64.0

    private func emitPointer(dx: Double, dy: Double) {
        pxRemX += dx; pxRemY += dy
        let ix = Int((pxRemX * FP_SCALE).rounded(.towardZero))
        let iy = Int((pxRemY * FP_SCALE).rounded(.towardZero))
        if ix != 0 || iy != 0 {
            pxRemX -= Double(ix) / FP_SCALE
            pxRemY -= Double(iy) / FP_SCALE
            EventTxPump.shared.queue(.pm(dx: ix, dy: iy))
        }
    }

    private func emitScroll(dx: Double, dy: Double) {
        scRemX += dx; scRemY += dy
        var ix = Int(scRemX.rounded(.towardZero))
        var iy = Int(scRemY.rounded(.towardZero))
        if ix != 0 || iy != 0 {
            scRemX -= Double(ix)
            scRemY -= Double(iy)
            
            if invertScroll { iy = -iy }
            EventTxPump.shared.queue(.sc(dx: ix, dy: iy))
        }
    }
    
    private func touchCount(in event: UIEvent?) -> Int {
        guard let e = event else { return 0 }
        return e.allTouches?.filter { $0.phase != .ended && $0.phase != .cancelled }.count ?? 0
    }

    private func currentTwoCenter(from event: UIEvent) -> CGPoint {
        let points = (event.allTouches ?? []).filter { $0.phase != .ended && $0.phase != .cancelled }
            .map { $0.location(in: self) }
        return center(of: points)
    }

    private func center(of pts: [CGPoint]) -> CGPoint {
        guard !pts.isEmpty else { return .zero }
        var sx: CGFloat = 0, sy: CGFloat = 0
        for p in pts { sx += p.x; sy += p.y }
        return CGPoint(x: sx / CGFloat(pts.count), y: sy / CGFloat(pts.count))
    }
}
