//
//  GamepadView.swift
//  Controlio
//
//  Created by Avis Luong on 11/4/25.
//

import SwiftUI
import CoreHaptics
import MultipeerConnectivity

struct GamepadView: View {
    @ObservedObject var mc: MCManager
    @EnvironmentObject var appSettings: AppSettings
    
    var onNavigateHome: (() -> Void)? = nil
    @State private var showSettings = false

    private func ui(for s: MCSessionState) -> (String, Color) {
        switch s {
        case .connected:
            return ("Connected", .green)
        case .connecting:
            return ("Connecting…", .orange)
        case .notConnected:
            return ("Disconnected", .red)
        @unknown default:
            return ("Disconnected", .red)
        }
    }

    @State private var engine: CHHapticEngine?
    @State private var leftStick = CGPoint.zero
    @State private var rightStick = CGPoint.zero
    @State private var lastAXSentLeft = Date.distantPast
    @State private var lastAXSentRight = Date.distantPast
    private let axInterval: TimeInterval = 1.0 / 60.0
    private let deadzone: CGFloat = 0.08
    
    private let stickTick = Timer.publish(
        every: 1.0 / 60.0,
        on: .main,
        in: .common
    ).autoconnect()
    
    @State private var hapticsReady = false

    var body: some View {
        GeometryReader { geo in
            let (statusText, dotColor) = ui(for: mc.sessionState)

            let w = geo.size.width
            let h = geo.size.height
            let isLandscape = w > h
            let isCompactWidth = w < 360
            let isUltraCompact = w < 340
            let verticalSpacing: CGFloat = isLandscape ? 6 : 4

            let shoulderHeight: CGFloat = max(36, min(52, h * 0.06))
            let shoulderWidth: CGFloat  = max(100, min(160, w * 0.35))

            let middleRowPadding: CGFloat = isLandscape ? 22 : (isUltraCompact ? 12 : (isCompactWidth ? 14 : 18))
            let stickRowPadding: CGFloat = isLandscape ? 20 : (isUltraCompact ? 12 : (isCompactWidth ? 14 : 16))

            let baseDpadKey: CGFloat = max(40, min(54, min(w, h) * 0.085))
            let baseDpadSpacing: CGFloat = 10
            let baseAbxySize: CGFloat = max(54, min(68, min(w, h) * 0.11))
            let baseClusterGap: CGFloat = isLandscape
                ? max(22, min(32, min(w, h) * 0.045))
                : max(24, min(34, min(w, h) * 0.05))
            let baseColumnGap: CGFloat = {
                let base = isLandscape
                    ? max(24, min(32, min(w, h) * 0.04))
                    : max(22, min(28, min(w, h) * 0.04))
                return isCompactWidth ? base * 0.85 : base
            }()
            let baseChipWidth: CGFloat = isCompactWidth ? 72 : 82
            let chipHorizontalPadding: CGFloat = isCompactWidth ? 10 : 12
            let chipStackPadding: CGFloat = isLandscape ? 10 : (isCompactWidth ? 6 : 8)

            let midRowAvailable = w - middleRowPadding * 2
            let estimatedMidWidth =
                baseDpadKey * 3 +
                baseDpadSpacing * 2 +
                baseAbxySize * 2 +
                baseClusterGap +
                baseColumnGap * 2 +
                baseChipWidth
            let primaryScale = min(1, midRowAvailable / estimatedMidWidth)

            let scaledDpadKey = baseDpadKey * primaryScale
            let scaledDpadSpacing = baseDpadSpacing * primaryScale
            let scaledAbxySize = baseAbxySize * primaryScale
            let scaledClusterGap = baseClusterGap * primaryScale
            let scaledColumnGap = baseColumnGap * primaryScale
            let scaledChipWidth = baseChipWidth * primaryScale

            let minDpadKey: CGFloat = isCompactWidth ? 28 : 34
            let minDpadSpacing: CGFloat = isCompactWidth ? 7 : 8
            let minAbxySize: CGFloat = isCompactWidth ? 41 : 46
            let minClusterGap: CGFloat = isCompactWidth ? 12 : 16
            let minColumnGap: CGFloat = isCompactWidth ? 10 : 14
            let minChipWidth: CGFloat = isCompactWidth ? 56 : 64

            let clampedDpadKey = max(minDpadKey, scaledDpadKey)
            let clampedDpadSpacing = max(minDpadSpacing, scaledDpadSpacing)
            let clampedAbxySize = max(minAbxySize, scaledAbxySize)
            let clampedClusterGap = max(minClusterGap, scaledClusterGap)
            let clampedColumnGap = max(minColumnGap, scaledColumnGap)
            let clampedChipWidth = max(minChipWidth, scaledChipWidth)

            let adjustedMidWidth =
                clampedDpadKey * 3 +
                clampedDpadSpacing * 2 +
                clampedAbxySize * 2 +
                clampedClusterGap +
                clampedColumnGap * 2 +
                clampedChipWidth
            let secondaryScale = min(1, midRowAvailable / adjustedMidWidth)

            let dpadKey = max(minDpadKey, clampedDpadKey * secondaryScale)
            let dpadSpacing = max(minDpadSpacing, clampedDpadSpacing * secondaryScale)
            let abxySize = max(minAbxySize, clampedAbxySize * secondaryScale)
            let clusterGap = max(minClusterGap, clampedClusterGap * secondaryScale)
            let columnGap = max(minColumnGap, clampedColumnGap * secondaryScale)
            let chipWidth = max(minChipWidth, clampedChipWidth * secondaryScale)
            let midRowWidth =
                dpadKey * 3 +
                dpadSpacing * 2 +
                abxySize * 2 +
                clusterGap +
                columnGap * 2 +
                chipWidth
            let midRowFrameWidthPortrait = min(midRowAvailable, midRowWidth)

            let stickGap = columnGap
            let stickRowAvailable = w - stickRowPadding * 2
            let baseStickRadius = min(w, h) * 0.18
            let minStickRadius: CGFloat = isCompactWidth ? 54 : 64
            let clampedStickRadius = max(minStickRadius, min(110, baseStickRadius))
            let maxStickRadiusByWidth = max(0, (stickRowAvailable - stickGap * 3) / 4)
            let stickRadius = min(clampedStickRadius, maxStickRadiusByWidth)
            let stickRowWidth = stickRadius * 4 + stickGap
            let stickRowFrameWidthPortrait = min(stickRowAvailable, stickRowWidth + stickGap)
            
            ZStack(alignment: .topLeading) {
                appSettings.bgColor.ignoresSafeArea()
                
                VStack(spacing: verticalSpacing) {
                    HStack {
                        Shoulder(label: "L1", width: shoulderWidth, height: shoulderHeight) { down in
                            sendButton(.l1, down)
                        }
                        Spacer(minLength: isLandscape ? 20 : 16)
                        Shoulder(label: "R1", width: shoulderWidth, height: shoulderHeight) { down in
                            sendButton(.r1, down)
                        }
                    }
                    .padding(.horizontal, isLandscape ? 26 : 22)
                    .padding(.top, isLandscape ? 0 : 2)
                    .padding(.bottom, 2)

                    HStack(alignment: .center, spacing: columnGap) {
                        DPad(keySize: dpadKey, spacing: dpadSpacing) { dir, down in
                            switch dir {
                            case .up:    sendButton(.dpadUp, down)
                            case .down:  sendButton(.dpadDown, down)
                            case .left:  sendButton(.dpadLeft, down)
                            case .right: sendButton(.dpadRight, down)
                            }
                        }
                        .frame(maxWidth: isLandscape ? .infinity : nil, alignment: isLandscape ? .leading : .center)

                        VStack(spacing: isLandscape ? 10 : 8) {
                            GPChip(label: "Select", horizontalPadding: chipHorizontalPadding) { down in sendButton(.select, down) }
                                .frame(width: chipWidth)
                            GPChip(label: "Start", horizontalPadding: chipHorizontalPadding) { down in sendButton(.start, down)  }
                                .frame(width: chipWidth)
                        }
                        .padding(.horizontal, chipStackPadding)
                        
                        ABXY(buttonSize: abxySize, gap: clusterGap) { btn, down in
                            switch btn {
                            case .a: sendButton(.a, down)
                            case .b: sendButton(.b, down)
                            case .x: sendButton(.x, down)
                            case .y: sendButton(.y, down)
                            }
                        }
                        .frame(maxWidth: isLandscape ? .infinity : nil, alignment: isLandscape ? .trailing : .center)
                    }
                    .frame(
                        width: isLandscape ? nil : midRowFrameWidthPortrait,
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, middleRowPadding)
                    .padding(.vertical, 0)
                    
                    HStack(alignment: .bottom, spacing: stickGap) {
                        Thumbstick(radius: stickRadius, value: $leftStick) { x, y in
                            sendStick(id: 0, x: x, y: y, lastSent: &lastAXSentLeft)
                        }
                        .frame(maxWidth: isLandscape ? .infinity : nil, alignment: isLandscape ? .leading : .center)
                        
                        Spacer(minLength: stickGap)
                        
                        Thumbstick(radius: stickRadius, value: $rightStick) { x, y in
                            sendStick(id: 1, x: x, y: y, lastSent: &lastAXSentRight)
                        }
                        .frame(maxWidth: isLandscape ? .infinity : nil, alignment: isLandscape ? .trailing : .center)
                    }
                    .frame(
                        width: isLandscape ? nil : stickRowFrameWidthPortrait,
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, stickRowPadding)
                    .padding(.top, 0)
                    .padding(.bottom, isLandscape ? 2 : 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .onAppear {
            prepareHaptics()
            mc.startBrowsingIfNeeded()
        }
        .onReceive(stickTick) { _ in
            pollSticks()
        }
        .navigationBarItems(
            trailing:
                HStack(spacing: 12) {
                    ConnectionIndicator(
                        statusText: ui(for: mc.sessionState).0,
                        dotColor: ui(for: mc.sessionState).1
                    )
                    .environmentObject(appSettings)

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(appSettings.primaryButton)
                            .padding(8)
                            .background(appSettings.cardColor)
                            .clipShape(Circle())
                            .shadow(color: appSettings.shadowColor, radius: 4, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(appSettings.strokeColor, lineWidth: 1)
                            )
                    }
                }
        )
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            GamepadSettingsView(
                onNavigateHome: onNavigateHome,
                mcManager: mc
            )
        }
    }
    
    private func pollSticks() {
        guard mc.sessionState == .connected else { return }
        
        sendStick(id: 0, x: leftStick.x,  y: leftStick.y,  lastSent: &lastAXSentLeft)
        sendStick(id: 1, x: rightStick.x, y: rightStick.y, lastSent: &lastAXSentRight)
    }
    private func sendButton(_ b: GPButton, _ down: Bool) {
        let keyHint = appSettings.keybind(for: b.settingsKey)
        mc.send(down ? .gpDown(b, ht: keyHint) : .gpUp(b, ht: keyHint))
        hapticTap()
    }
    
    private func sendStick(id: Int, x: CGFloat, y: CGFloat, lastSent: inout Date) {
        let vx = clampDeadzone(x, dz: deadzone)
        let vy = clampDeadzone(y, dz: deadzone)

        // Apply inversion
        let adjustedX = appSettings.invertHorizontal ? -vx : vx
        let adjustedY = appSettings.invertVertical ? -vy : vy

        // Apply sensitivity
        let finalX = adjustedX * CGFloat(appSettings.horizontalSensitivity)
        let finalY = adjustedY * CGFloat(appSettings.verticalSensitivity)

        let sx = Int(max(-1, min(1, finalX)) * 1000)
        let sy = Int(max(-1, min(1, finalY)) * 1000)

        let now = Date()
        let forceNeutral = (sx == 0 && sy == 0)

        if !forceNeutral && now.timeIntervalSince(lastSent) < axInterval {
            return
        }
        lastSent = now

        mc.send(.ax(id: id, x: sx, y: sy), reliable: false)
    }
    
    private func clampDeadzone(_ v: CGFloat, dz: CGFloat) -> CGFloat {
        let mag = abs(v)
        if mag < dz { return 0 }
        let sign: CGFloat = v >= 0 ? 1.0 : -1.0
        return sign * (mag - dz) / (1 - dz)
    }
    
    private func prepareHaptics() {
    #if targetEnvironment(simulator)
        // Simulator doesn’t support haptics
        hapticsReady = false
        return
    #endif
        DispatchQueue.main.async {
            let caps = CHHapticEngine.capabilitiesForHardware()
            guard caps.supportsHaptics else {
                hapticsReady = false
                return
            }
            do {
                if engine == nil {
                    engine = try CHHapticEngine()
                    engine?.stoppedHandler = { _ in
                    }
                    engine?.resetHandler = { [weak engine] in
                        do { try engine?.start() } catch {}
                    }
                }

                try engine?.start()
                hapticsReady = true
            } catch {
                #if DEBUG
                print("Haptics init failed: \(error)")
                #endif
                hapticsReady = false
            }
        }
    }
    
    private func hapticTap() {
        guard let engine else { return }
        let sharp = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [sharp], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch { }
    }
}

struct Shoulder: View {
    let label: String
    let width: CGFloat
    let height: CGFloat
    let onChange: (Bool) -> Void
    @State private var pressed = false
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let fill = isDark
            ? (pressed ? Color.white.opacity(0.22) : Color.white.opacity(0.12))
            : (pressed ? appSettings.cardColor.opacity(0.95) : appSettings.cardColor)
        let stroke = isDark ? Color.white.opacity(0.15) : appSettings.strokeColor
        let text = appSettings.primaryText
        RoundedRectangle(cornerRadius: height/2, style: .continuous)
            .fill(fill)
            .overlay(Text(label).font(.headline).foregroundStyle(text).padding(.horizontal, 8))
            .frame(width: width, height: height)
            .overlay(RoundedRectangle(cornerRadius: height/2).stroke(stroke, lineWidth: 1))
            .onLongPressGesture(minimumDuration: 0, pressing: { isDown in
                if pressed != isDown { pressed = isDown; onChange(isDown) }
            }, perform: {})
    }
}

private struct GPChip: View {
    let label: String
    let horizontalPadding: CGFloat
    let onChange: (Bool) -> Void
    @State private var pressed = false
    @EnvironmentObject var appSettings: AppSettings

    init(
        label: String,
        horizontalPadding: CGFloat = 14,
        onChange: @escaping (Bool) -> Void
    ) {
        self.label = label
        self.horizontalPadding = horizontalPadding
        self.onChange = onChange
    }

    var body: some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let fill = isDark
            ? (pressed ? Color.white.opacity(0.25) : Color.white.opacity(0.12))
            : (pressed ? appSettings.cardColor.opacity(0.92) : appSettings.cardColor)
        let stroke = isDark ? Color.white.opacity(0.15) : appSettings.strokeColor
        let text = appSettings.primaryText

        Text(label)
            .font(.subheadline)
            .foregroundStyle(text)
            .padding(.vertical, 8)
            .padding(.horizontal, horizontalPadding)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .background(fill)
            .overlay(Capsule().stroke(stroke, lineWidth: 1))
            .clipShape(Capsule())
            .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
                if pressed != isPressing { pressed = isPressing; onChange(isPressing) }
            }, perform: {})
    }
}

enum ABXYBtn { case a, b, x, y }

struct ABXY: View {
    let buttonSize: CGFloat
    let gap: CGFloat
    let onChange: (ABXYBtn, Bool) -> Void
    @State private var a = false
    @State private var b = false
    @State private var x = false
    @State private var y = false
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        ZStack {
            VStack(spacing: gap) {
                roundBtn("Y", pressed: $y) { onChange(.y, $0) }
                roundBtn("A", pressed: $a) { onChange(.a, $0) }
            }
            HStack(spacing: gap) {
                roundBtn("X", pressed: $x) { onChange(.x, $0) }
                roundBtn("B", pressed: $b) { onChange(.b, $0) }
            }
        }
        .frame(minWidth: buttonSize*2 + gap, minHeight: buttonSize*2 + gap)
    }
    private func roundBtn(_ t: String, pressed: Binding<Bool>, on: @escaping (Bool)->Void) -> some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let fill = isDark
            ? (pressed.wrappedValue ? Color.white.opacity(0.30) : Color.white.opacity(0.16))
            : (pressed.wrappedValue ? appSettings.cardColor.opacity(0.95) : appSettings.cardColor)
        let stroke = isDark ? Color.white.opacity(0.15) : appSettings.strokeColor
        let text = appSettings.primaryText
        
        return Circle()
            .fill(fill)
            .overlay(Circle().stroke(stroke, lineWidth: 1))
            .frame(width: buttonSize, height: buttonSize)
            .overlay(Text(t).font(.headline).foregroundStyle(text))
            .onLongPressGesture(minimumDuration: 0, pressing: { isDown in
                if pressed.wrappedValue != isDown { pressed.wrappedValue = isDown; on(isDown) }
            }, perform: {})
    }
}

enum DPadDir { case up, down, left, right }

struct DPad: View {
    let keySize: CGFloat
    let spacing: CGFloat
    let onChange: (DPadDir, Bool) -> Void
    @State private var u = false
    @State private var d = false
    @State private var l = false
    @State private var r = false
    @EnvironmentObject var appSettings: AppSettings

    init(
        keySize: CGFloat,
        spacing: CGFloat = 10,
        onChange: @escaping (DPadDir, Bool) -> Void
    ) {
        self.keySize = keySize
        self.spacing = spacing
        self.onChange = onChange
    }

    var body: some View {
        VStack(spacing: spacing) {
            dKey("▲", pressed: $u) { onChange(.up, $0) }
            HStack(spacing: spacing) {
                dKey("◀", pressed: $l) { onChange(.left, $0) }
                Rectangle().fill(Color.clear).frame(width: keySize, height: keySize)
                dKey("▶", pressed: $r) { onChange(.right, $0) }
            }
            dKey("▼", pressed: $d) { onChange(.down, $0) }
        }
    }
    private func dKey(_ t: String, pressed: Binding<Bool>, on: @escaping (Bool)->Void) -> some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let fill = isDark
            ? (pressed.wrappedValue ? Color.white.opacity(0.28) : Color.white.opacity(0.14))
            : (pressed.wrappedValue ? appSettings.cardColor.opacity(0.95) : appSettings.cardColor)
        let stroke = isDark ? Color.white.opacity(0.12) : appSettings.strokeColor
        let text = appSettings.primaryText

        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(fill)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(stroke, lineWidth: 1))
            .frame(width: keySize, height: keySize)
            .overlay(Text(t).foregroundStyle(text))
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        on(true)
                        on(false)
                    }
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed.wrappedValue { pressed.wrappedValue = true; on(true) }
                    }
                    .onEnded { _ in
                        if pressed.wrappedValue { pressed.wrappedValue = false; on(false) }
                    }
            )
    }
}

struct Thumbstick: View {
    let radius: CGFloat
    @Binding var value: CGPoint
    let onChange: (CGFloat, CGFloat) -> Void
    @State private var drag = CGSize.zero
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let ringStroke = isDark ? Color.white.opacity(0.22) : appSettings.strokeColor
        let ringFill = isDark ? Color.white.opacity(0.08) : appSettings.cardColor
        let knobFill = isDark ? Color.white.opacity(0.22) : appSettings.cardColor
        let knobStroke = isDark ? Color.white.opacity(0.18) : appSettings.strokeColor
        let hitRadius = radius * 1.4
	
        return ZStack {
            Circle().strokeBorder(ringStroke, lineWidth: 2)
                .background(Circle().fill(ringFill))
                .clipShape(Circle())
                .frame(width: radius*2, height: radius*2)
            Circle()
                .fill(knobFill)
                .overlay(Circle().stroke(knobStroke, lineWidth: 1))
                .frame(width: max(58, radius * 0.7), height: max(58, radius * 0.7))
                .offset(drag)
        }
        .frame(width: radius*2, height: radius*2)
        .contentShape(Circle().inset(by: -max(hitRadius - radius, 0))) // bigger hit ring lets you start off the knob
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let dx = g.translation.width
                    let dy = g.translation.height
                    let clamped = clampToCircle(CGSize(width: dx, height: dy), limit: radius)
                    drag = clamped
                    let nx = clamped.width / radius
                    let ny = clamped.height / radius
                    value = CGPoint(x: nx, y: ny)
                    onChange(nx, ny)
                }
                .onEnded { _ in
                    drag = .zero
                    value = .zero
                    onChange(0, 0)
                }
        )
    }
    
    private func clampToCircle(_ v: CGSize, limit: CGFloat) -> CGSize {
        let d = sqrt(v.width*v.width + v.height*v.height)
        if d <= limit { return v }
        let s = limit / d
        return CGSize(width: v.width*s, height: v.height*s)
    }
}
