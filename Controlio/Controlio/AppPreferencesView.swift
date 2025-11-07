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
                    .foregroundColor(appSettings.primaryText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                // General Settings
                SettingsCard(title: "General") {
                    PickerRow(title: "Theme", selection: $appSettings.selectedTheme, options: themes)
                    PickerRow(title: "Language", selection: $appSettings.selectedLanguage, options: languages)
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
        .background(appSettings.bgColor.ignoresSafeArea())
    }
}

// Reusable Cards
struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    @EnvironmentObject var appSettings: AppSettings

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("SF Pro", size: 18).weight(.bold))
                .foregroundColor(appSettings.primaryText)
            content
        }
        .padding()
        .background(appSettings.cardColor)
        .cornerRadius(12)
        .shadow(color: appSettings.shadowColor, radius: 4, y: 1)
    }
}

// Reusable Picker Row
struct PickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(appSettings.primaryText)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(appSettings.secondaryText)
        }
        .padding()
        .background(appSettings.cardColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appSettings.strokeColor, lineWidth: 0.5)
        )
        .cornerRadius(8)
    }
}

// Reusable Toggle Row
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(appSettings.primaryText)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: appSettings.primaryButton))
        }
        .padding()
        .background(appSettings.cardColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appSettings.strokeColor, lineWidth: 0.5)
        )
        .cornerRadius(8)
    }
}

#Preview {
    AppPreferencesView()
}
