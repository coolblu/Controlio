//
//  HelpView.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        VStack {
            Text("Application Help")
                .font(.largeTitle)
                .bold()
            
            // Add profile settings here
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HelpView()
}
