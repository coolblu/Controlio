//
//  TrackpadSettingsView.swift
//  Controlio
//
//  Created by Evan Weng on 11/7/25.
//

import SwiftUI

struct TrackpadSettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var pointerSensitivity: Double
    @Binding var scrollSensitivity: Double
    @Binding var reverseScroll: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pointer")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sensitivity")
                            Spacer()
                            Text(String(format: "%.1fx", pointerSensitivity))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $pointerSensitivity, in: 0.5...3.0, step: 0.1)
                    }
                }
                
                Section(header: Text("Scrolling")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scroll Speed")
                            Spacer()
                            Text(String(format: "%.1fx", scrollSensitivity))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $scrollSensitivity, in: 0.5...3.0, step: 0.1)
                    }
                    
                    Toggle("Reverse Scroll Direction", isOn: $reverseScroll)
                }
                
                Section(header: Text("Reset")) {
                    Button(action: {
                        pointerSensitivity = 1.0
                        scrollSensitivity = 1.0
                        reverseScroll = false
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Trackpad Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
