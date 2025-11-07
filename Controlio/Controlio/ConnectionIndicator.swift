//
//  ConnectionIndicator.swift
//  Controlio
//
//  Created by Avis Luong on 11/4/25.
//

import SwiftUI

struct ConnectionIndicator: View {
    let statusText: String
    let color: Color
    var onDark: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(statusText)
                .font(.footnote)
                .foregroundStyle(onDark ? Color.white.opacity(0.9) : .secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Group {
                if onDark {
                    Color.white.opacity(0.08)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Color.clear
                }
            }
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
