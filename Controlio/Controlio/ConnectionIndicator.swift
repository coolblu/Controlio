//
//  ConnectionIndicator.swift
//  Controlio
//
//  Created by Avis Luong on 11/4/25.
//

import SwiftUI

struct ConnectionIndicator: View {
    @EnvironmentObject var appSettings: AppSettings
    
    let statusText: String
    let dotColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)

            Text(
                NSLocalizedString(
                    statusText,
                    bundle: appSettings.bundle,
                    comment: ""
                )
            )
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(appSettings.primaryText)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(appSettings.cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(appSettings.strokeColor, lineWidth: 1)
                )
        )
        .shadow(color: appSettings.shadowColor, radius: 4, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
