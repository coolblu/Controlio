//
//  ManageProfileView.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI
import FirebaseAuth

struct ManageProfileView: View {
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appSettings: AppSettings

    @State private var userName: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingDeleteConfirmation: Bool = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case newPassword
        case confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Manage Profile")
                    .font(.system(size: 32, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .foregroundColor(appSettings.primaryText)

                // User Info Card
                VStack(alignment: .leading, spacing: 16) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.custom("SF Pro", size: 12))
                            .foregroundColor(appSettings.secondaryText)

                        TextField("Enter your name", text: $userName)
                            .padding()
                            .background(appSettings.cardColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .name ? appSettings.primaryButton : appSettings.strokeColor, lineWidth: 1)
                            )
                            .foregroundColor(appSettings.primaryText)
                            .focused($focusedField, equals: .name)
                    }

                    // Email Field (read-only)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.custom("SF Pro", size: 12))
                            .foregroundColor(appSettings.secondaryText)

                        Text(userManager.email)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(Color.gray)
                    }

                    Button(action: { saveName() }) {
                        Text("Save Name")
                            .font(.custom("SF Pro", size: 16))
                            .foregroundColor(appSettings.buttonText)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(appSettings.primaryButton)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(appSettings.cardColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appSettings.strokeColor, lineWidth: 0.5)
                )

                // Password Change Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Password")
                        .font(.custom("SF Pro", size: 12))
                        .foregroundColor(appSettings.secondaryText)

                    // New Password
                    SecureToggleField(
                        placeholder: "Enter new password",
                        text: $password,
                        show: $showPassword,
                        isFocused: focusedField == .newPassword
                    )
                    .focused($focusedField, equals: .newPassword)
                    .foregroundColor(appSettings.primaryText)
                    .background(appSettings.cardColor)

                    // Confirm Password
                    SecureToggleField(
                        placeholder: "Confirm new password",
                        text: $confirmPassword,
                        show: $showConfirmPassword,
                        isFocused: focusedField == .confirmPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .foregroundColor(appSettings.primaryText)
                    .background(appSettings.cardColor)

                    Button(action: { changePassword() }) {
                        Text("Change Password")
                            .font(.custom("SF Pro", size: 16))
                            .foregroundColor(appSettings.buttonText)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(appSettings.primaryButton)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(appSettings.cardColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appSettings.strokeColor, lineWidth: 0.5)
                )

                // Delete Account Button
                Button(action: { showingDeleteConfirmation = true }) {
                    Text("Delete Account")
                        .font(.custom("SF Pro", size: 16))
                        .foregroundColor(appSettings.destructiveButton)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(appSettings.cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(appSettings.destructiveButton, lineWidth: 2)
                        )
                }
                .padding(.top, 16)
                .alert(isPresented: $showingDeleteConfirmation) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) { deleteAccount() },
                        secondaryButton: .cancel()
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(appSettings.bgColor.ignoresSafeArea())
        .onAppear { userName = userManager.displayName }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func saveName() {
        userManager.updateDisplayName(to: userName) { error in
            if let error = error {
                alertMessage = "Failed to update name: \(error.localizedDescription)"
            } else {
                alertMessage = "Name updated successfully."
            }
            showingAlert = true
        }
    }

    private func changePassword() {
        guard !password.isEmpty else {
            alertMessage = "Password cannot be empty."
            showingAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showingAlert = true
            return
        }

        guard let user = Auth.auth().currentUser else {
            alertMessage = "No logged-in user."
            showingAlert = true
            return
        }

        user.updatePassword(to: password) { error in
            if let error = error {
                alertMessage = "Failed to change password: \(error.localizedDescription)"
            } else {
                alertMessage = "Password changed successfully."
                // Clear input fields
                password = ""
                confirmPassword = ""
            }
            showingAlert = true
        }
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        user.delete { error in
            if let error = error {
                alertMessage = "Failed to delete account: \(error.localizedDescription)"
                showingAlert = true
            } else {
                // Account deleted, log out
                try? Auth.auth().signOut()
                withAnimation(.easeInOut(duration: 0.4)) {
                    isLoggedIn = false
                }
            }
        }
    }
}
