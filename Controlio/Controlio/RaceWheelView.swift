//
//  RaceWheelView.swift
//  Controlio
//
//

import SwiftUI
import CoreMotion
import CoreHaptics
import MultipeerConnectivity
import UIKit
import AudioToolbox

struct RaceWheelView: View {
    @ObservedObject var mc: MCManager
    @EnvironmentObject var appSettings: AppSettings
    
    var onNavigateHome: (() -> Void)? = nil
    
    // Settings state
    @State private var showSettings = false

    // Motion manager
    @StateObject private var motion = MotionManager()
    
    // Haptics
    @State private var engine: CHHapticEngine?
    @State private var hapticsReady = false
    
    // Steering state
    @State private var steeringAngle: Double = 0
    @State private var lastSteeringSent = Date.distantPast
    private let steeringInterval: TimeInterval = 1.0 / 60.0
    
    // Pedal states
    @State private var gasPressed = false
    @State private var brakePressed = false
    
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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                appSettings.bgColor.ignoresSafeArea()
                landscapeLayout(geo: geo)
            }
        }
        .disableSwipeBack()
        .onAppear {
            prepareHaptics()
            motion.start()
            mc.startBrowsingIfNeeded()
            OrientationManager.lockLandscape()
        }
        .onDisappear {
            motion.stop()
            OrientationManager.unlock()
        }
        .onReceive(motion.$pitch) { pitch in
            updateSteering(pitch: pitch)
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
            RaceWheelSettingsView(
                onNavigateHome: onNavigateHome,
                mcManager: mc
            )
        }
    }
        
    @ViewBuilder
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        let w = max(geo.size.width, geo.size.height)
        let h = min(geo.size.width, geo.size.height)
        let pedalHeight = min(h * 0.5, 180)
        let wheelSize = min(w * 0.35, h * 0.75, 260)
        
        HStack(spacing: 0) {
            VStack {
                Spacer()
                PedalButton(
                    label: NSLocalizedString("BRAKE", bundle: appSettings.bundle, comment: ""),
                    color: .red,
                    isPressed: $brakePressed,
                    height: pedalHeight
                ) { down in
                    sendPedal(.brake, down: down)
                }
                .environmentObject(appSettings)
                .padding(.bottom, 20)
            }
            .frame(width: w * 0.22)
            
            VStack {
                Spacer()
                SteeringWheelView(
                    angle: steeringAngle,
                    size: wheelSize
                )
                .environmentObject(appSettings)
                
                SteeringIndicator(value: steeringAngle)
                    .frame(width: wheelSize, height: 8)
                    .padding(.top, 16)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            VStack {
                Spacer()
                PedalButton(
                    label: NSLocalizedString("GAS", bundle: appSettings.bundle, comment: ""),
                    color: .green,
                    isPressed: $gasPressed,
                    height: pedalHeight
                ) { down in
                    sendPedal(.gas, down: down)
                }
                .environmentObject(appSettings)
                .padding(.bottom, 20)
            }
            .frame(width: w * 0.22)
        }
        .padding(.horizontal, 16)
    }
    
    private func updateSteering(pitch: Double) {
        let sensitivity = appSettings.steeringSensitivity
        let deadzone = appSettings.steeringDeadzone
        let invert = appSettings.invertSteering
        
        var normalized = pitch / (Double.pi / 5) * sensitivity
        
        if abs(normalized) < deadzone {
            normalized = 0
        } else {
            let sign = normalized >= 0 ? 1.0 : -1.0
            normalized = sign * (abs(normalized) - deadzone) / (1.0 - deadzone)
        }
        
        normalized = max(-1, min(1, normalized))
        
        if invert {
            normalized = -normalized
        }
        
        steeringAngle = normalized
        
        let now = Date()
        guard now.timeIntervalSince(lastSteeringSent) >= steeringInterval else { return }
        lastSteeringSent = now
        
        let steerValue = Int(normalized * 1000)
        let receiverDeadzone = Int(appSettings.raceWheelReceiverDeadzone * 100)
        let holdThreshold = Int(appSettings.raceWheelHoldThreshold * 100)
        let tapRate = Int(appSettings.raceWheelTapRate * 100)
        
        mc.send(.rw(steer: steerValue, deadzone: receiverDeadzone, holdThreshold: holdThreshold, tapRate: tapRate), reliable: false)
    }
    
    enum Pedal { case gas, brake }
    
    private func sendPedal(_ pedal: Pedal, down: Bool) {
        if down {
            if appSettings.vibrationFeedback {
                hapticTap(strength: appSettings.hapticStrength)
            }
            if appSettings.soundEffects {
                AudioServicesPlaySystemSound(1104)
            }
        }

        switch pedal {
        case .gas:
            let keyHint = appSettings.keybind(for: "raceGas")
            mc.send(down ? .gpDown(.r2, ht: keyHint) : .gpUp(.r2, ht: keyHint))
        case .brake:
            let keyHint = appSettings.keybind(for: "raceBrake")
            mc.send(down ? .gpDown(.l1, ht: keyHint) : .gpUp(.l1, ht: keyHint))
        }
    }
        
    private func prepareHaptics() {
        #if targetEnvironment(simulator)
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
                    engine?.stoppedHandler = { _ in }
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
    
    private func hapticTap(strength: String = "Medium") {
        guard let engine else { return }

        let intensity: Float
        let sharpness: Float
        switch strength.lowercased() {
        case "light":
            intensity = 0.3
            sharpness = 0.3
        case "heavy":
            intensity = 1.0
            sharpness = 0.9
        default: // medium
            intensity = 0.8
            sharpness = 0.7
        }

        let sharp = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
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

final class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            
            self?.roll = motion.attitude.roll
            self?.pitch = motion.attitude.pitch
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct SteeringWheelView: View {
    let angle: Double
    let size: CGFloat
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let rimColor = isDark ? Color.white.opacity(0.15) : appSettings.cardColor
        let strokeColor = isDark ? Color.white.opacity(0.3) : appSettings.strokeColor
        let accentColor = appSettings.primaryButton
        
        ZStack {
            Circle()
                .stroke(strokeColor, lineWidth: size * 0.08)
                .background(Circle().fill(rimColor))
                .frame(width: size, height: size)
            
            Circle()
                .fill(appSettings.bgColor)
                .frame(width: size * 0.55, height: size * 0.55)
            
            Circle()
                .fill(rimColor)
                .overlay(Circle().stroke(strokeColor, lineWidth: 2))
                .frame(width: size * 0.25, height: size * 0.25)
            
            ForEach([0, 120, 240], id: \.self) { deg in
                Capsule()
                    .fill(strokeColor)
                    .frame(width: size * 0.04, height: size * 0.18)
                    .offset(y: -size * 0.35)
                    .rotationEffect(.degrees(Double(deg)))
            }
            
            Circle()
                .fill(accentColor)
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(y: -size * 0.42)
        }
        .rotationEffect(.degrees(angle * 90))
        .animation(.easeOut(duration: 0.05), value: angle)
    }
}

struct SteeringIndicator: View {
    let value: Double
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let isDark = appSettings.selectedTheme == "Dark"
            let trackColor = isDark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2)
            let indicatorColor = appSettings.primaryButton
            
            ZStack(alignment: .center) {
                Capsule()
                    .fill(trackColor)
                
                Rectangle()
                    .fill(appSettings.secondaryText.opacity(0.5))
                    .frame(width: 2)
                
                Circle()
                    .fill(indicatorColor)
                    .frame(width: h * 1.5, height: h * 1.5)
                    .offset(x: value * (w / 2 - h))
                    .animation(.easeOut(duration: 0.05), value: value)
            }
        }
    }
}

struct PedalButton: View {
    let label: String
    let color: Color
    @Binding var isPressed: Bool
    var width: CGFloat? = nil
    var height: CGFloat = 100
    let onChange: (Bool) -> Void
    
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        let isDark = appSettings.selectedTheme == "Dark"
        let baseColor = isDark ? color.opacity(0.3) : color.opacity(0.15)
        let pressedColor = isDark ? color.opacity(0.6) : color.opacity(0.4)
        let strokeColor = isDark ? color.opacity(0.5) : color.opacity(0.6)
        
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isPressed ? pressedColor : baseColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(strokeColor, lineWidth: isPressed ? 3 : 2)
            )
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: label == "GAS" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 28))
                    Text(label)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(isDark ? color : color.opacity(0.9))
            )
            .frame(width: width, height: height)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                if isPressed != pressing {
                    isPressed = pressing
                    onChange(pressing)
                }
            }, perform: {})
    }
}

final class OrientationManager {
    static func lockLandscape() {
        AppDelegate.orientationLock = .landscape
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    static func unlock() {
        AppDelegate.orientationLock = .all
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
