//
//  TrackpadView.swift
//  Controlio
//
//  Created by Avis Luong on 10/20/25.
//

import SwiftUI
import MultipeerConnectivity

struct TrackpadView: View {
    let mc: MCManager
    var onNavigateHome: (() -> Void)? = nil
    // callbacks
    var onPointer: (Int, Int) -> Void = { _, _ in }
    var onScroll: (Int, Int) -> Void  = { _, _ in }
    var onButton: (Int, Int) -> Void  = { _, _ in }
        
    // variables for settings
    @State private var pointerSensitivity: Double = 1.0
    @State private var scrollSensitivity: Double = 1.0
    @State private var reverseScroll: Bool = false
    
    @State private var isDragging = false
    @State private var statusText = "Searching…"
    @State private var dotColor: Color = .orange
    @State private var showSettings = false
        
    var body: some View {
            ZStack {
                Color(red: 0.957, green: 0.968, blue: 0.980).ignoresSafeArea()

                VStack(spacing: 8) {

                    HStack {
                        ConnectionIndicator(statusText: statusText, color: dotColor)
                        
                        Spacer()
                        
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    
                    TouchPadSurface(
                        pointerMultiplier: pointerSensitivity,
                        scrollMultiplier:  scrollSensitivity,
                        onPointer: { dx, dy in
                            mc.send(.pm(dx: dx, dy: dy))
                        },
                        onScroll: { dx, dy in
                            let m = reverseScroll ? -1 : 1
                            mc.send(.sc(dx: dx * m, dy: dy * m))
                        },
                        onLeftDown: {
                            isDragging = true
                            mc.send(.leftDown)
                        },
                        onLeftUp: {
                            isDragging = false
                            mc.send(.leftUp)
                        },
                        onLeftClick: {
                            mc.send(.leftDown); mc.send(.leftUp)
                        },
                        onRightClick: {
                            mc.send(.rightDown); mc.send(.rightUp)
                        }
                    )
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 8)
                    .padding(16)
                }

                if isDragging {
                    VStack {
                        HStack {
                            Spacer()
                            Text("Drag")
                                .font(.caption2)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.black.opacity(0.75))
                                .foregroundColor(.white)
                                .cornerRadius(8)
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
                            pointerSensitivity: $pointerSensitivity,
                            scrollSensitivity: $scrollSensitivity,
                            reverseScroll: $reverseScroll
                        )
                    }
        
            .onAppear {
                // start browsing + wire status updates
                mc.onStateChange = { state in
                    DispatchQueue.main.async {
                        switch state {
                        case .connected:
                            self.statusText = "Connected"
                            self.dotColor = .green
                        case .connecting:
                            self.statusText = "Connecting…"
                            self.dotColor = .orange
                        case .notConnected:
                            fallthrough
                        @unknown default:
                            self.statusText = "Searching…"
                            self.dotColor = .orange
                        }
                    }
                }
            }
        }
    }

//    #Preview {
//        NavigationView { TrackpadView() }
//    }
