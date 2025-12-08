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
    
    private var velocityX = 0.0, velocityY = 0.0
    private let smoothingFactor = 0.4
    private let edgeExclusionWidth: CGFloat = 20.0
    
    var invertScroll: Bool = false
    
    private var isDragging = false
    private var dragStartTime: Date?
    private var hasMoved = false
    
    private var threeFingerStartCenter: CGPoint?
    private var threeFingerAccumulatedX: CGFloat = 0
    private let threeFingerSwipeThreshold: CGFloat = 80
    private var threeFingerGestureTriggered = false
    
    private let rightEdgeWidth: CGFloat = 30
    private var rightEdgeSwipeStarted = false
    private var rightEdgeStartX: CGFloat = 0
    private let rightEdgeSwipeThreshold: CGFloat = 60
    private var rightEdgeGestureTriggered = false
    
    private var fiveFingerStartPositions: [CGPoint] = []
    private var fiveFingerStartSpread: CGFloat = 0
    private let fiveFingerPinchThreshold: CGFloat = 0.5
    private var fiveFingerGestureTriggered = false
    
    private lazy var twoFingerTap: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(didTwoFingerTap(_:)))
        g.numberOfTouchesRequired = 2
        g.numberOfTapsRequired = 1
        g.cancelsTouchesInView = false
        g.delaysTouchesBegan = false
        g.delegate = self
        return g
    }()
    
    private lazy var doubleTapDrag: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(didDoubleTapDrag(_:)))
        g.minimumPressDuration = 0.0
        g.numberOfTapsRequired = 1
        g.cancelsTouchesInView = false
        g.delaysTouchesBegan = false
        g.delegate = self
        return g
    }()

    private lazy var tap: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        g.numberOfTapsRequired = 1
        g.cancelsTouchesInView = false
        g.delaysTouchesBegan = false
        g.delegate = self
        return g
    }()

    private lazy var longPress: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        g.minimumPressDuration = 0.25
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
        addGestureRecognizer(doubleTapDrag)
        addGestureRecognizer(twoFingerTap)

        tap.require(toFail: twoFingerTap)
        tap.require(toFail: doubleTapDrag)
        longPress.require(toFail: doubleTapDrag)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
    
    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let loc = touch.location(in: self)
        if loc.x < edgeExclusionWidth {
            return false
        }
        return true
    }

    @objc private func didTap(_ g: UITapGestureRecognizer) {
        if g.state == .ended && !isDragging {
            onLeftClick()
        }
    }

    @objc private func didLongPress(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began:
            isDragging = true
            onLeftDown()
        case .ended, .cancelled, .failed:
            if isDragging {
                isDragging = false
                onLeftUp()
            }
        default: break
        }
    }
    
    @objc private func didTwoFingerTap(_ g: UITapGestureRecognizer) {
        if g.state == .ended { onRightClick() }
    }
    
    @objc private func didDoubleTapDrag(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began:
            isDragging = true
            onLeftDown()
        case .changed:
            break
        case .ended, .cancelled, .failed:
            if isDragging {
                isDragging = false
                onLeftUp()
            }
        default: break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let e = event else { return }
        let allActive = e.allTouches?.filter { $0.phase != .ended && $0.phase != .cancelled } ?? []
        let allPositions = allActive.map { $0.location(in: self) }
        let touchCount = allActive.count
        
        let validTouches = allActive.filter { $0.location(in: self).x >= edgeExclusionWidth }
        
        for touch in allActive {
            let loc = touch.location(in: self)
            if loc.x >= bounds.width - rightEdgeWidth && touchCount == 1 {
                rightEdgeSwipeStarted = true
                rightEdgeStartX = loc.x
                rightEdgeGestureTriggered = false
            }
        }
        
        if touchCount == 3 {
            threeFingerStartCenter = center(of: allPositions)
            threeFingerAccumulatedX = 0
            threeFingerGestureTriggered = false
        }
        
        if touchCount == 5 {
            fiveFingerStartPositions = allPositions
            fiveFingerStartSpread = calculateSpread(of: allPositions)
            fiveFingerGestureTriggered = false
        }
        
        guard !validTouches.isEmpty else { return }
        
        if validTouches.count == 1 && touchCount == 1 {
            lastOne = validTouches.first?.location(in: self)
            hasMoved = false
            velocityX = 0
            velocityY = 0
        } else if touchCount == 2 {
            lastTwoCenter = center(of: validTouches.map { $0.location(in: self) })
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let e = event else { return }
        
        let allActive = e.allTouches?.filter { $0.phase != .ended && $0.phase != .cancelled } ?? []
        let allPositions = allActive.map { $0.location(in: self) }
        let touchCount = allActive.count
        
        if touchCount == 3, let startCenter = threeFingerStartCenter, !threeFingerGestureTriggered {
            let currentCenter = center(of: allPositions)
            let deltaX = currentCenter.x - startCenter.x
            threeFingerAccumulatedX = deltaX
            
            if abs(deltaX) >= threeFingerSwipeThreshold {
                threeFingerGestureTriggered = true
                if deltaX > 0 {
                    EventTxPump.shared.queue(.gs(kind: .threeFingerSwipeRight))
                } else {
                    EventTxPump.shared.queue(.gs(kind: .threeFingerSwipeLeft))
                }
            }
            return
        }
        
        if rightEdgeSwipeStarted && touchCount == 1 && !rightEdgeGestureTriggered {
            if let touch = allActive.first {
                let currentX = touch.location(in: self).x
                let deltaX = rightEdgeStartX - currentX
                
                if deltaX >= rightEdgeSwipeThreshold {
                    rightEdgeGestureTriggered = true
                    EventTxPump.shared.queue(.gs(kind: .rightEdgeSwipe))
                }
            }
            return
        }
        
        if touchCount == 5 && !fiveFingerGestureTriggered && fiveFingerStartSpread > 0 {
            let currentSpread = calculateSpread(of: allPositions)
            let spreadRatio = currentSpread / fiveFingerStartSpread
            
            if spreadRatio <= fiveFingerPinchThreshold {
                fiveFingerGestureTriggered = true
                EventTxPump.shared.queue(.gs(kind: .fiveFingerPinch))
            }
            return
        }
        
        let validActive = allActive.filter { $0.location(in: self).x >= edgeExclusionWidth }
        let validCount = validActive.count

        if touchCount == 2 && validCount >= 2 {
            let current = center(of: validActive.map { $0.location(in: self) })
            if let prev = lastTwoCenter {
                let dx = Double(current.x - prev.x) * scrollMultiplier
                let dy = Double(current.y - prev.y) * scrollMultiplier
                emitScroll(dx: dx, dy: dy)
            }
            lastTwoCenter = current
            lastOne = nil
        } else if touchCount == 1 && validCount == 1 && !rightEdgeSwipeStarted {
            let validTouches = touches.filter { $0.location(in: self).x >= edgeExclusionWidth }
            guard let touch = validTouches.first else { return }
            
            let coalescedTouches = e.coalescedTouches(for: touch) ?? [touch]
            
            for t in coalescedTouches {
                let p = t.location(in: self)
                guard p.x >= edgeExclusionWidth else { continue }
                
                if let prev = lastOne {
                    let rawDX = Double(p.x - prev.x) * pointerMultiplier
                    let rawDY = Double(p.y - prev.y) * pointerMultiplier
                    
                    velocityX = velocityX * (1.0 - smoothingFactor) + rawDX * smoothingFactor
                    velocityY = velocityY * (1.0 - smoothingFactor) + rawDY * smoothingFactor
                    
                    emitPointer(dx: velocityX, dy: velocityY)
                    hasMoved = true
                }
                lastOne = p
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let remaining = touchCount(in: event)
        if remaining <= 1 { lastTwoCenter = nil }
        if remaining == 0 {
            lastOne = nil
            velocityX = 0
            velocityY = 0
            resetGestureState()
        }
        
        if remaining < 3 {
            threeFingerStartCenter = nil
            threeFingerAccumulatedX = 0
            threeFingerGestureTriggered = false
        }
        if remaining < 5 {
            fiveFingerStartPositions = []
            fiveFingerStartSpread = 0
            fiveFingerGestureTriggered = false
        }
        if remaining == 0 {
            rightEdgeSwipeStarted = false
            rightEdgeGestureTriggered = false
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastOne = nil
        lastTwoCenter = nil
        pxRemX = 0; pxRemY = 0
        scRemX = 0; scRemY = 0
        velocityX = 0; velocityY = 0
        resetGestureState()
    }
    
    private func resetGestureState() {
        threeFingerStartCenter = nil
        threeFingerAccumulatedX = 0
        threeFingerGestureTriggered = false
        rightEdgeSwipeStarted = false
        rightEdgeGestureTriggered = false
        fiveFingerStartPositions = []
        fiveFingerStartSpread = 0
        fiveFingerGestureTriggered = false
    }
    
    private let FP_SCALE = 64.0

    private func emitPointer(dx: Double, dy: Double) {
        pxRemX += dx
        pxRemY += dy
        
        let ix = Int(floor(pxRemX * FP_SCALE))
        let iy = Int(floor(pxRemY * FP_SCALE))
        
        if ix != 0 || iy != 0 {
            pxRemX -= Double(ix) / FP_SCALE
            pxRemY -= Double(iy) / FP_SCALE
            EventTxPump.shared.queue(.pm(dx: ix, dy: iy))
        }
    }

    private func emitScroll(dx: Double, dy: Double) {
        scRemX += dx
        scRemY += dy
        
        let ix = Int(floor(scRemX))
        var iy = Int(floor(scRemY))
        
        if ix != 0 || iy != 0 {
            scRemX -= Double(ix)
            scRemY -= Double(iy)
            
            if invertScroll { iy = -iy }
            EventTxPump.shared.queue(.sc(dx: ix, dy: iy))
        }
    }
    
    private func touchCount(in event: UIEvent?) -> Int {
        guard let e = event else { return 0 }
        return e.allTouches?.filter { touch in
            touch.phase != .ended && touch.phase != .cancelled &&
            touch.location(in: self).x >= edgeExclusionWidth
        }.count ?? 0
    }

    private func currentTwoCenter(from event: UIEvent) -> CGPoint {
        let points = (event.allTouches ?? []).filter { touch in
            touch.phase != .ended && touch.phase != .cancelled &&
            touch.location(in: self).x >= edgeExclusionWidth
        }.map { $0.location(in: self) }
        return center(of: points)
    }

    private func center(of pts: [CGPoint]) -> CGPoint {
        guard !pts.isEmpty else { return .zero }
        var sx: CGFloat = 0, sy: CGFloat = 0
        for p in pts { sx += p.x; sy += p.y }
        return CGPoint(x: sx / CGFloat(pts.count), y: sy / CGFloat(pts.count))
    }
    
    private func calculateSpread(of pts: [CGPoint]) -> CGFloat {
        guard pts.count >= 2 else { return 0 }
        let c = center(of: pts)
        var totalDist: CGFloat = 0
        for p in pts {
            let dx = p.x - c.x
            let dy = p.y - c.y
            totalDist += sqrt(dx * dx + dy * dy)
        }
        return totalDist / CGFloat(pts.count)
    }
}
