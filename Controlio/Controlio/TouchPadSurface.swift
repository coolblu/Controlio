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
    
    private lazy var onePan: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(onePanChanged(_:)))
        g.minimumNumberOfTouches = 1
        g.maximumNumberOfTouches = 1
        g.delegate = self
        return g
    }()

    private lazy var twoPan: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(twoPanChanged(_:)))
        g.minimumNumberOfTouches = 2
        g.maximumNumberOfTouches = 2
        g.delegate = self
        return g
    }()

    private lazy var tap: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        g.numberOfTapsRequired = 1
        g.delegate = self
        return g
    }()

    private lazy var rightTap: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(didRightTap(_:)))
        g.numberOfTapsRequired = 2
        g.delegate = self
        return g
    }()

    private lazy var longPress: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        g.minimumPressDuration = 0.25
        g.delegate = self
        return g
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear

        addGestureRecognizer(onePan)
        addGestureRecognizer(twoPan)
        addGestureRecognizer(tap)
        addGestureRecognizer(rightTap)
        addGestureRecognizer(longPress)

        tap.require(toFail: rightTap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    @objc private func onePanChanged(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: self)
        g.setTranslation(.zero, in: self)
        let dx = Int(Double(t.x) * pointerMultiplier)
        let dy = Int(Double(t.y) * pointerMultiplier)
        if dx != 0 || dy != 0 { onPointer(dx, dy) }
    }

    @objc private func twoPanChanged(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: self)
        g.setTranslation(.zero, in: self)
        let dx = Int(Double(t.x) * scrollMultiplier)
        let dy = Int(Double(t.y) * scrollMultiplier)
        if dx != 0 || dy != 0 { onScroll(dx, dy) }
    }

    @objc private func didTap(_ g: UITapGestureRecognizer) {
        if g.state == .ended { onLeftClick() }
    }

    @objc private func didRightTap(_ g: UITapGestureRecognizer) {
        if g.state == .ended { onRightClick() }
    }

    @objc private func didLongPress(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began: onLeftDown()
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
            for t in expanded {
                let current = currentTwoCenter(from: e)
                guard let prev = lastTwoCenter else { lastTwoCenter = current; continue }
                let dx = Double(current.x - prev.x) * scrollMultiplier
                let dy = Double(current.y - prev.y) * scrollMultiplier
                emitScroll(dx: dx, dy: dy)
                lastTwoCenter = current
            }
        } else {
            // One-finger pointer
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

    private func emitPointer(dx: Double, dy: Double) {
        pxRemX += dx; pxRemY += dy
        let ix = Int(pxRemX.rounded(.towardZero))
        let iy = Int(pxRemY.rounded(.towardZero))
        if ix != 0 || iy != 0 {
            pxRemX -= Double(ix)
            pxRemY -= Double(iy)
            onPointer(ix, iy)
        }
    }

    private func emitScroll(dx: Double, dy: Double) {
        scRemX += dx; scRemY += dy
        let ix = Int(scRemX.rounded(.towardZero))
        let iy = Int(scRemY.rounded(.towardZero))
        if ix != 0 || iy != 0 {
            scRemX -= Double(ix)
            scRemY -= Double(iy)
            onScroll(ix, iy)
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
