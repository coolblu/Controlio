//
//  TrackpadView.swift
//  Controlio
//
//  Created by Avis Luong on 10/20/25.
//

import SwiftUI
import MultipeerConnectivity

struct TrackpadView: View {
    @ObservedObject var mc: MCManager
    var onNavigateHome: (() -> Void)? = nil
    
    @EnvironmentObject var appSettings: AppSettings
    
    // callbacks
    var onPointer: (Int, Int) -> Void = { _, _ in }
    var onScroll: (Int, Int) -> Void  = { _, _ in }
    var onButton: (Int, Int) -> Void  = { _, _ in }
        
    // variables for settings
    @State private var pointerSensitivity: Double = 1.0
    @State private var scrollSensitivity: Double = 1.0
    @State private var reverseScroll: Bool = false
    
    @State private var isDragging = false
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
        
    var body: some View {
        let (statusText, dotColor) = ui(for: mc.sessionState)
        ZStack {
            appSettings.bgColor.ignoresSafeArea()

            VStack(spacing: 8) {

                HStack {
                    ConnectionIndicator(statusText: statusText, dotColor: dotColor)
                        .environmentObject(appSettings)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
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
                    .padding(.trailing, 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                
                TouchPadSurface(
                    pointerMultiplier: pointerSensitivity,
                    scrollMultiplier:  scrollSensitivity,
                    invertScroll: reverseScroll,
                    onPointer: { dx, dy in
                        EventTxPump.shared.queue(.pm(dx: dx, dy: dy))
                    },
                    onScroll: { dx, dy in
                        let m = reverseScroll ? -1 : 1
                        EventTxPump.shared.queue(.sc(dx: dx, dy: dy * m))
                    },
                    onLeftDown: {
                        isDragging = true
                        mc.send(.leftDown, reliable: true)
                    },
                    onLeftUp: {
                        isDragging = false
                        mc.send(.leftUp,   reliable: true)
                    },
                    onLeftClick: {
                        mc.send(.leftDown, reliable: true); mc.send(.leftUp, reliable: true)
                    },
                    onRightClick: {
                        mc.send(.rightDown, reliable: true); mc.send(.rightUp, reliable: true)
                    }
                )
                .background(appSettings.cardColor)
                .cornerRadius(18)
                .shadow(color: appSettings.shadowColor, radius: 12, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 18).stroke(appSettings.strokeColor, lineWidth: 1)
                )
                .padding(16)
            }

            if isDragging {
                VStack {
                    HStack {
                        Spacer()
                        Text("Drag")
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(appSettings.cardColor.opacity(0.9))
                            .foregroundColor(appSettings.primaryText)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(appSettings.strokeColor, lineWidth: 1)
                            )
                            .shadow(color: appSettings.shadowColor, radius: 4, y: 2)
                            .padding([.top, .trailing], 12)
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    
        .sheet(isPresented: $showSettings) {
                    TrackpadSettingsView(
                        onNavigateHome: onNavigateHome,
                        mcManager: mc,
                        pointerSensitivity: $pointerSensitivity,
                        scrollSensitivity: $scrollSensitivity,
                        reverseScroll: $reverseScroll
                    )
                }
        .environmentObject(appSettings)
        .disableSwipeBack()
        .onAppear {
            // start browsing + wire status updates
            mc.startBrowsingIfNeeded()
            EventTxPump.shared.start(mc: mc)
        }
    }
}

//    #Preview {
//        NavigationView { TrackpadView() }
//    }
