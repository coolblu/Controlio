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
            // responsive sizing
            let shoulderHeight: CGFloat = max(36, min(52, h * 0.06))
            let shoulderWidth: CGFloat  = max(100, min(160, w * 0.35))
            let stickRadius: CGFloat    = max(70, min(110, min(w, h) * 0.18))
            let abxySize: CGFloat       = max(54, min(68, min(w, h) * 0.11))
            let dpadKey: CGFloat        = max(40, min(54, min(w, h) * 0.085))
            let clusterGap: CGFloat     = isLandscape
                ? max(22, min(32, min(w, h) * 0.045))
                : max(24, min(34, min(w, h) * 0.05))
            let columnGap: CGFloat      = isLandscape
                ? max(24, min(32, min(w, h) * 0.04))
                : max(20, min(28, min(w, h) * 0.04))
            
            ZStack(alignment: .topLeading) {
                appSettings.bgColor.ignoresSafeArea()
                
                VStack(spacing: isLandscape ? 6 : 6) {
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

                    HStack(spacing: 18) {
                        Spacer()
                        GPChip(label: "Select") { down in sendButton(.select, down) }
                        GPChip(label: "Start")  { down in sendButton(.start, down)  }
                        Spacer()
                    }
                    .padding(.horizontal, isLandscape ? 24 : 20)
                    .padding(.bottom, 0)

                    HStack(alignment: .center, spacing: columnGap) {
                        DPad(keySize: dpadKey) { dir, down in
                            switch (dir, down) {
                            case (.up, true):    mc.send(.gpDown(.dpadUp))
                            case (.up, false):   mc.send(.gpUp(.dpadUp))
                            case (.down, true):  mc.send(.gpDown(.dpadDown))
                            case (.down, false): mc.send(.gpUp(.dpadDown))
                            case (.left, true):  mc.send(.gpDown(.dpadLeft))
                            case (.left, false): mc.send(.gpUp(.dpadLeft))
                            case (.right, true): mc.send(.gpDown(.dpadRight))
                            case (.right, false):mc.send(.gpUp(.dpadRight))
                            }
                            hapticTap()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, isLandscape ? 4 : 0)
                        
                        Spacer(minLength: columnGap)
                        
                        ABXY(buttonSize: abxySize, gap: clusterGap) { btn, down in
                            switch btn {
                            case .a: sendButton(.a, down)
                            case .b: sendButton(.b, down)
                            case .x: sendButton(.x, down)
                            case .y: sendButton(.y, down)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.leading, isLandscape ? 4 : 0)
                    }
                    .padding(.horizontal, isLandscape ? 22 : 18)
                    .padding(.vertical, 0)
                    
                    HStack(alignment: .bottom, spacing: columnGap) {
                        Thumbstick(radius: stickRadius, value: $leftStick) { x, y in
                            sendStick(id: 0, x: x, y: y, lastSent: &lastAXSentLeft)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, isLandscape ? 4 : 0)
                        
                        Spacer(minLength: columnGap)
                        
                        Thumbstick(radius: stickRadius, value: $rightStick) { x, y in
                            sendStick(id: 1, x: x, y: y, lastSent: &lastAXSentRight)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.leading, isLandscape ? 4 : 0)
                    }
                    .padding(.horizontal, isLandscape ? 20 : 16)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ConnectionIndicator(statusText: ui(for: mc.sessionState).0, dotColor: ui(for: mc.sessionState).1)
                    .environmentObject(appSettings)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func pollSticks() {
        guard mc.sessionState == .connected else { return }
        
        sendStick(id: 0, x: leftStick.x,  y: leftStick.y,  lastSent: &lastAXSentLeft)
        sendStick(id: 1, x: rightStick.x, y: rightStick.y, lastSent: &lastAXSentRight)
    }
    private func sendButton(_ b: GPButton, _ down: Bool) {
        mc.send(down ? .gpDown(b) : .gpUp(b))
        hapticTap()
    }
    
    private func sendStick(id: Int, x: CGFloat, y: CGFloat, lastSent: inout Date) {
        let vx = clampDeadzone(x, dz: deadzone)
        let vy = clampDeadzone(y, dz: deadzone)

        let sx = Int((max(-1, min(1, vx))) * 1000)
        let sy = Int((max(-1, min(1, vy))) * 1000)

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
    let onChange: (Bool) -> Void
    @State private var pressed = false
    @EnvironmentObject var appSettings: AppSettings

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
            .padding(.vertical, 8).padding(.horizontal, 14)
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
    let onChange: (DPadDir, Bool) -> Void
    @State private var u = false
    @State private var d = false
    @State private var l = false
    @State private var r = false
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        VStack(spacing: 10) {
            dKey("▲", pressed: $u) { onChange(.up, $0) }
            HStack(spacing: 10) {
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
            .onLongPressGesture(minimumDuration: 0, pressing: { isDown in
                if pressed.wrappedValue != isDown { pressed.wrappedValue = isDown; on(isDown) }
            }, perform: {})
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
