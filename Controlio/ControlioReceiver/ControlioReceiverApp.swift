//
//  ControlioReceiverApp.swift
//  ControlioReceiver
//
//  Created by Avis Luong on 10/20/25.
//

import SwiftUI

@main
struct ControlioReceiverApp: App {
    @StateObject private var vm = ReceiverVM()
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text("Controlio Mac Receiver")
                    .font(.title2).bold()
                HStack {
                    Circle().fill(vm.connected ? .green : .orange).frame(width: 10, height: 10)
                    Text(vm.status)
                        .foregroundColor(.secondary)
                }
                Divider()
                ScrollView {
                    ForEach(vm.logs.indices, id: \.self) { i in
                        Text(vm.logs[i]).font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
            .frame(minWidth: 420, minHeight: 260)
        }
    }
}

final class ReceiverVM: ObservableObject {
    @Published var status = "Starting…"
    @Published var connected = false
    @Published var logs: [String] = []
    private let mc = MCManager()

    init() {
        mc.onDebug = { [weak self] in self?.log($0)}
        
        mc.onStateChange = { [weak self] s in
            DispatchQueue.main.async {
                self?.connected = (s == .connected)
                self?.status = {
                    switch s {
                    case .connected: return "Connected"
                    case .connecting: return "Connecting…"
                    case .notConnected: return "Searching…"
                    @unknown default: return "Unknown"
                    }
                }()
                self?.log("MC state: \(s.rawValue)")
            }
        }
        
        mc.onEvents = { events in
            for e in events {
                EventPump.shared.enqueue(e)
            }
        }

                mc.startAdvertising()
        log("Advertising. Open Trackpad on iPhone to test.")
        print("Advertising. Open Trackpad on iPhone to test.") // also to console
    }

    private func log(_ s: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(s)
            if logs.count > 200 { logs.removeFirst(logs.count - 200) }
        }
    }
}
