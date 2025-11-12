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
    let languages = ["English", "French", "Spanish"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // Title
                Text(NSLocalizedString("App Preferences", bundle: appSettings.bundle, comment: ""))
                    .font(.custom("SF Pro", size: 32).weight(.bold))
                    .foregroundColor(appSettings.primaryText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                // General Settings
                SettingsCard(title: NSLocalizedString("General", bundle: appSettings.bundle, comment: "")) {
                    PickerRow(title: NSLocalizedString("Theme", bundle: appSettings.bundle, comment: ""), selection: $appSettings.selectedTheme, options: themes)
                    PickerRow(title: NSLocalizedString("Language", bundle: appSettings.bundle, comment: ""), selection: $appSettings.selectedLanguage, options: languages)
                }

                // Controller Settings
                SettingsCard(title: NSLocalizedString("Controller", bundle: appSettings.bundle, comment: "")) {
                    ToggleRow(title: NSLocalizedString("Show Tips", bundle: appSettings.bundle, comment: ""), isOn: $appSettings.showTips)
                }

                // Notification Settings
                SettingsCard(title: NSLocalizedString("Notifications", bundle: appSettings.bundle, comment: "")) {
                    ToggleRow(title: NSLocalizedString("Connection Alerts", bundle: appSettings.bundle, comment: ""), isOn: $appSettings.connectionAlerts)
                    ToggleRow(title: NSLocalizedString("Update Reminders", bundle: appSettings.bundle, comment: ""), isOn: $appSettings.updateReminders)
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
            Text(NSLocalizedString(title, bundle: appSettings.bundle, comment: ""))
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(appSettings.primaryText)
            Spacer()

            Picker(selection: $selection, label:
                Text(NSLocalizedString(selection, bundle: appSettings.bundle, comment: ""))
                    .font(.custom("SF Pro", size: 16))
            ) {
                ForEach(options, id: \.self) { option in
                    Text(NSLocalizedString(option, bundle: appSettings.bundle, comment: ""))
                        .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(appSettings.primaryButton)
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
            Text(NSLocalizedString(title, bundle: appSettings.bundle, comment: ""))
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
