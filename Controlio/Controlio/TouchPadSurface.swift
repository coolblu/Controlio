//
//  TouchPadSurface.swift
//  Controlio
//
//  Created by Avis Luong on 10/20/25.
//

import SwiftUI

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
    var onScroll: (Int, Int) -> Void  = { _, _ in }
    var onLeftDown: () -> Void = {}
    var onLeftUp: () -> Void = {}
    var onLeftClick: () -> Void = {}
    var onRightClick: () -> Void = {}

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
}
