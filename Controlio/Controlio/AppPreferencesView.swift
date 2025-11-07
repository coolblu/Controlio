//
//  AppPreferencesView.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI

struct AppPreferencesView: View {
    @EnvironmentObject var appSettings: AppSettings

    let themes = ["Light", "Dark"]
    let languages = ["System Default", "English", "Spanish"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // Title
                Text("App Preferences")
                    .font(.custom("SF Pro", size: 32).weight(.bold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                // General Settings
                SettingsCard(title: "General") {
                    PickerRow(title: "Theme", selection: $appSettings.selectedTheme, options: ["Light", "Dark"])
                    PickerRow(title: "Language", selection: $appSettings.selectedLanguage, options: ["System Default", "English", "Spanish"])
                }

                // Controller Settings
                SettingsCard(title: "Controller") {
                    ToggleRow(title: "Show Tips", isOn: $appSettings.showTips)
                }

                // Notification Settings
                SettingsCard(title: "Notifications") {
                    ToggleRow(title: "Connection Alerts", isOn: $appSettings.connectionAlerts)
                    ToggleRow(title: "Update Reminders", isOn: $appSettings.updateReminders)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.98).ignoresSafeArea())
    }
}

// Reusable Cards
struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("SF Pro", size: 18).weight(.bold))
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
            content
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 1)
    }
}

// Reusable Picker Row
struct PickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.42))
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.89, green: 0.89, blue: 0.89), lineWidth: 0.5)
        )
        .cornerRadius(8)
    }
}

// Reusable Toggle Row
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.orange))
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.89, green: 0.89, blue: 0.89), lineWidth: 0.5)
        )   
        .cornerRadius(8)
    }
}

#Preview {
    AppPreferencesView()
}
