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
    // callbacks
    var onPointer: (Int, Int) -> Void = { _, _ in }
    var onScroll: (Int, Int) -> Void  = { _, _ in }
    var onButton: (Int, Int) -> Void  = { _, _ in }
        
    // hardcoded for alpha
    private let pointerSensitivity: Double = 1.0  // change in code if needed
    private let scrollSensitivity: Double = 1.0
    private let reverseScroll: Bool = false
    
    @State private var isDragging = false
    @State private var statusText = "Searching…"
    @State private var dotColor: Color = .orange

    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
            ZStack {
                appSettings.bgColor.ignoresSafeArea()

                VStack(spacing: 8) {
                    // tiny status row
                    ConnectionIndicator(statusText: statusText, color: dotColor)
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
                    .background(appSettings.cardColor)
                    .cornerRadius(18)
                    .shadow(color: appSettings.shadowColor, radius: 12, y: 8)
                    .padding(16)
                }

                if isDragging {
                    VStack {
                        HStack {
                            Spacer()
                            Text("Drag")
                                .font(.caption2)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(appSettings.primaryText.opacity(0.75))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding([.top, .trailing], 12)
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                }
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
