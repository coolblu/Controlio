//
//  ContentView.swift
//  Controlio
//
//  Created by Avis Luong on 10/1/25.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Image("controlio_logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 0.9)
                    .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 8)
                    .position(x: w / 2, y: h * 0.28)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview { ContentView() }
