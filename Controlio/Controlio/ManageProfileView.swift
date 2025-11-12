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
                Text(NSLocalizedString("Manage Profile", bundle: appSettings.bundle, comment: ""))
                    .font(.system(size: 32, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .foregroundColor(appSettings.primaryText)

                // User Info Card
                VStack(alignment: .leading, spacing: 16) {

                    // Name Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("Name", bundle: appSettings.bundle, comment: ""))
                            .font(.custom("SF Pro", size: 12))
                            .foregroundColor(appSettings.secondaryText)

                        TextField(NSLocalizedString("Enter your name", bundle: appSettings.bundle, comment: ""), text: $userName)
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
                        Text(NSLocalizedString("Email", bundle: appSettings.bundle, comment: ""))
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
                        Text(NSLocalizedString("Save Name", bundle: appSettings.bundle, comment: ""))
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
                    Text(NSLocalizedString("Password", bundle: appSettings.bundle, comment: ""))
                        .font(.custom("SF Pro", size: 12))
                        .foregroundColor(appSettings.secondaryText)

                    // New Password
                    SecureToggleField(
                        placeholder: NSLocalizedString("Enter new password", bundle: appSettings.bundle, comment: ""),
                        text: $password,
                        show: $showPassword,
                        isFocused: focusedField == .newPassword
                    )
                    .focused($focusedField, equals: .newPassword)
                    .foregroundColor(appSettings.primaryText)
                    .background(appSettings.cardColor)

                    // Confirm Password
                    SecureToggleField(
                        placeholder: NSLocalizedString("Confirm new password", bundle: appSettings.bundle, comment: ""),
                        text: $confirmPassword,
                        show: $showConfirmPassword,
                        isFocused: focusedField == .confirmPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .foregroundColor(appSettings.primaryText)
                    .background(appSettings.cardColor)

                    Button(action: { changePassword() }) {
                        Text(NSLocalizedString("Change Password", bundle: appSettings.bundle, comment: ""))
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
                    Text(NSLocalizedString("Delete Account", bundle: appSettings.bundle, comment: ""))
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
                        title: Text(NSLocalizedString("Delete Account", bundle: appSettings.bundle, comment: "")),
                        message: Text(NSLocalizedString("Are you sure you want to delete your account? This action cannot be undone.", bundle: appSettings.bundle, comment: "")),
                        primaryButton: .destructive(Text(NSLocalizedString("Delete", bundle: appSettings.bundle, comment: ""))) { deleteAccount() },
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
            Button(NSLocalizedString("OK", bundle: appSettings.bundle, comment: ""), role: .cancel) { }
        }
    }

    private func saveName() {
        userManager.updateDisplayName(to: userName) { error in
            if let error = error {
                alertMessage = NSLocalizedString("Failed to update name: \(error.localizedDescription)", bundle: appSettings.bundle, comment: "")
            } else {
                alertMessage = NSLocalizedString("Name updated successfully.", bundle: appSettings.bundle, comment: "")
            }
            showingAlert = true
        }
    }

    private func changePassword() {
        guard !password.isEmpty else {
            alertMessage = NSLocalizedString("Password cannot be empty.", bundle: appSettings.bundle, comment: "")
            showingAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = NSLocalizedString("Passwords do not match.", bundle: appSettings.bundle, comment: "")
            showingAlert = true
            return
        }

        guard let user = Auth.auth().currentUser else {
            alertMessage = NSLocalizedString("No logged-in user.", bundle: appSettings.bundle, comment: "")
            showingAlert = true
            return
        }

        user.updatePassword(to: password) { error in
            if let error = error {
                alertMessage = NSLocalizedString("Failed to change password: \(error.localizedDescription)", bundle: appSettings.bundle, comment: "")
            } else {
                alertMessage = NSLocalizedString("Password changed successfully.", bundle: appSettings.bundle, comment: "")
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
                alertMessage = NSLocalizedString("Failed to delete account: \(error.localizedDescription)", bundle: appSettings.bundle, comment: "")
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
