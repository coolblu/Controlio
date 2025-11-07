//
//  AuthComponents.swift
//  Controlio
//
//  Created by Jerry Lin on 10/22/25.
//

import SwiftUI

/// Button with consistent styling and press effect.
struct StyledButton: View {
    let title: String
    let color: Color
    let textColor: Color
    let iconName: String?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(iconName)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(title)
                    .foregroundColor(textColor)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
    }
}


/// Reusable text input field with consistent padding, corner radius, and shadow.
struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder shown when text is empty
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
            }

            TextField("", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .textContentType(.none)
                .padding(.leading, 12)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Password input field with an eye icon to toggle visibility.
struct SecureToggleField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool
    let isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder field text
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
            }

            HStack {
                // Secure or plain text depending on toggle
                Group {
                    if show {
                        TextField("", text: $text)
                            .textContentType(.none)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .textContentType(.none)
                            .padding(.trailing, 36)
                    } else {
                        SecureField("", text: $text)
                            .textContentType(.none)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .textContentType(.none)
                            .padding(.trailing, 36)
                    }
                }
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.trailing, 36)

                // Eye button toggles password visibility
                Button(action: { show.toggle() }) {
                    Image(systemName: show ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
            .padding(.leading, 12)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
