import SwiftUI

struct SettingsView: View {
    @AppStorage("requireAuthentication") private var requireAuthentication = false
    @StateObject private var authManager = BiometricAuthManager.shared
    @StateObject private var passcodeManager = AppPasscodeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPasscodeSetup = false
    @State private var showingPasscodeVerification = false
    @State private var showingPasscodeDisableConfirmation = false
    @State private var isAuthenticating = false
    @State private var verificationPurpose: VerificationPurpose = .changePasscode
    
    // Reminder settings
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 22
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var showingPermissionDeniedAlert = false
    
    enum VerificationPurpose {
        case changePasscode
        case disableAppLock
        case enableAppLock
    }
    
    var body: some View {
        NavigationStack {
            List {
                // TEMPORARILY DISABLED: App Lock feature hidden for initial release
                // Section("Privacy & Security") {
                //     Toggle(isOn: Binding(
                //         get: { requireAuthentication },
                //         set: { newValue in
                //             if newValue {
                //                 enableAppLock()
                //             } else {
                //                 disableAppLock()
                //             }
                //         }
                //     )) {
                //         HStack {
                //             Image(systemName: authManager.biometricIcon)
                //                 .foregroundColor(.accentColor)
                //                 .frame(width: 24)
                //
                //             VStack(alignment: .leading, spacing: 2) {
                //                 Text("App Lock")
                //                     .font(.body)
                //
                //                 if authManager.biometricType != .none {
                //                     Text("Require \(authManager.biometricName) to open app")
                //                         .font(.caption)
                //                         .foregroundColor(.secondary)
                //                 } else if passcodeManager.hasPasscode {
                //                     Text("Require app passcode to open app")
                //                         .font(.caption)
                //                         .foregroundColor(.secondary)
                //                 } else {
                //                     Text("Set up app passcode to enable lock")
                //                         .font(.caption)
                //                         .foregroundColor(.secondary)
                //                 }
                //             }
                //         }
                //     }
                //
                //     // Show passcode change option if app passcode is set
                //     if passcodeManager.hasPasscode {
                //         Button(action: {
                //             verificationPurpose = .changePasscode
                //             showingPasscodeVerification = true
                //         }) {
                //             HStack {
                //                 Image(systemName: "key")
                //                     .foregroundColor(.accentColor)
                //                     .frame(width: 24)
                //
                //                 VStack(alignment: .leading, spacing: 2) {
                //                     Text("Change App Passcode")
                //                         .font(.body)
                //                         .foregroundColor(.primary)
                //
                //                     Text("Update your 4-digit app passcode")
                //                         .font(.caption)
                //                         .foregroundColor(.secondary)
                //                 }
                //
                //                 Spacer()
                //
                //                 Image(systemName: "chevron.right")
                //                     .font(.caption)
                //                     .foregroundColor(.secondary)
                //             }
                //         }
                //         .buttonStyle(PlainButtonStyle())
                //     }
                // }

                // Section("About") {
                //     HStack {
                //         Image(systemName: "info.circle")
                //             .foregroundColor(.accentColor)
                //             .frame(width: 24)
                        
                //         VStack(alignment: .leading, spacing: 2) {
                //             Text("Data Storage")
                //             Text("All photos and notes are stored locally on your device")
                //                 .font(.caption)
                //                 .foregroundColor(.secondary)
                //         }
                //     }
                    
                //     HStack {
                //         Image(systemName: "lock.shield")
                //             .foregroundColor(.accentColor)
                //             .frame(width: 24)
                        
                //         VStack(alignment: .leading, spacing: 2) {
                //             Text("Privacy First")
                //             Text("No accounts, no cloud sync, no tracking")
                //                 .font(.caption)
                //                 .foregroundColor(.secondary)
                //         }
                //     }
                // }

                // MARK: - Reminder Section
                Section {
                    Toggle(String(localized: "settings.reminder.daily_reminder"), isOn: Binding(
                        get: { dailyReminderEnabled },
                        set: { newValue in
                            if newValue {
                                enableReminder()
                            } else {
                                disableReminder()
                            }
                        }
                    ))
                    
                    if dailyReminderEnabled {
                        DatePicker(
                            String(localized: "settings.reminder.time"),
                            selection: Binding(
                                get: {
                                    var components = DateComponents()
                                    components.hour = reminderHour
                                    components.minute = reminderMinute
                                    return Calendar.current.date(from: components) ?? Date()
                                },
                                set: { newDate in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    reminderHour = components.hour ?? 22
                                    reminderMinute = components.minute ?? 0
                                    NotificationManager.shared.scheduleDailyReminder(
                                        hour: reminderHour,
                                        minute: reminderMinute
                                    )
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text(String(localized: "settings.reminder.title"))
                }

                Section {
                    HStack {
                        Spacer()

                        VStack(alignment: .center, spacing: 4) {
                            // if let appIcon = getAppIcon() {
                            //     Image(uiImage: appIcon)
                            //         .resizable()
                            //         .frame(width: 32, height: 32)
                            //         .clipShape(RoundedRectangle(cornerRadius: 6))
                            // } else {
                                ZStack {
                                    Image(systemName: "sun.max")
                                        // .foregroundColor(.white)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 32))
                                        .fontWeight(.heavy)
                                    Image(systemName: "app")
                                        // .foregroundColor(.white)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 60))
                                        .fontWeight(.regular)
                                }
                            // }

                            Text(String(localized: "settings.app_name"))
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .fontWeight(.heavy)

                            Text(String(localized: "settings.app_tagline"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .fontWeight(.light)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            authManager.checkBiometricAvailability()
        }
        .sheet(isPresented: $showingPasscodeSetup) {
            PasscodeSetupView {
                authManager.checkBiometricAvailability()
            }
        }
        .fullScreenCover(isPresented: $showingPasscodeVerification) {
            PasscodeEntryView(
                title: {
                    switch verificationPurpose {
                    case .changePasscode: return "Verify Current Passcode"
                    case .disableAppLock: return "Disable App Lock"
                    case .enableAppLock: return "Enable App Lock"
                    }
                }(),
                subtitle: {
                    switch verificationPurpose {
                    case .changePasscode: return "Enter your current passcode to change it"
                    case .disableAppLock: return "Enter your current passcode to disable app lock"
                    case .enableAppLock: return "Enter your current passcode to enable app lock"
                    }
                }(),
                onSuccess: {
                    showingPasscodeVerification = false
                    switch verificationPurpose {
                    case .changePasscode:
                        showingPasscodeSetup = true
                    case .disableAppLock:
                        requireAuthentication = false
                    case .enableAppLock:
                        // Set authenticated state to avoid immediate lock screen
                        authManager.isAuthenticated = true
                        requireAuthentication = true
                    }
                },
                onCancel: {
                    showingPasscodeVerification = false
                }
            )
            .navigationBarHidden(true)
        }
        .alert(String(localized: "settings.reminder.permission_title"), isPresented: $showingPermissionDeniedAlert) {
            Button(String(localized: "settings.reminder.open_settings")) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.reminder.permission_message"))
        }
    }
    
    // MARK: - Reminder Functions
    
    private func enableReminder() {
        Task {
            let status = await NotificationManager.shared.checkAuthorizationStatus()
            
            await MainActor.run {
                switch status {
                case .notDetermined:
                    Task {
                        let granted = await NotificationManager.shared.requestAuthorization()
                        await MainActor.run {
                            if granted {
                                dailyReminderEnabled = true
                                NotificationManager.shared.scheduleDailyReminder(
                                    hour: reminderHour,
                                    minute: reminderMinute
                                )
                            } else {
                                dailyReminderEnabled = false
                                showingPermissionDeniedAlert = true
                            }
                        }
                    }
                case .authorized, .provisional:
                    dailyReminderEnabled = true
                    NotificationManager.shared.scheduleDailyReminder(
                        hour: reminderHour,
                        minute: reminderMinute
                    )
                case .denied:
                    dailyReminderEnabled = false
                    showingPermissionDeniedAlert = true
                @unknown default:
                    dailyReminderEnabled = false
                }
            }
        }
    }
    
    private func disableReminder() {
        dailyReminderEnabled = false
        NotificationManager.shared.cancelDailyReminder()
    }
    
    private func enableAppLock() {
        // If no authentication method available, show passcode setup
        if !authManager.canUseAppAuthentication {
            showingPasscodeSetup = true
            return
        }
        
        // If we have biometrics, use them for verification
        if authManager.biometricType != .none {
            isAuthenticating = true
            Task {
                await authManager.authenticate()
                
                await MainActor.run {
                    if authManager.isAuthenticated {
                        // Keep authenticated state to avoid immediate lock screen
                        requireAuthentication = true
                    }
                    isAuthenticating = false
                }
            }
        } else if passcodeManager.hasPasscode {
            // If we have app passcode, verify it before enabling
            verificationPurpose = .enableAppLock
            showingPasscodeVerification = true
        } else {
            // This shouldn't happen due to canUseAppAuthentication check above
            showingPasscodeSetup = true
        }
    }
    
    private func disableAppLock() {
        // If app passcode is set, require verification before disabling
        if passcodeManager.hasPasscode {
            verificationPurpose = .disableAppLock
            showingPasscodeVerification = true
        } else {
            // If only biometric auth, disable immediately
            requireAuthentication = false
        }
    }
    
    private func getAppIcon() -> UIImage? {
        // First try the specific daygram image we found
        if let icon = UIImage(named: "daygram") {
            return icon
        }
        
        // Try different possible app icon names
        let possibleNames = ["AppIcon60x60", "AppIcon76x76", "AppIcon40x40", "AppIcon29x29", "AppIcon"]
        
        for name in possibleNames {
            if let icon = UIImage(named: name) {
                return icon
            }
        }
        
        // Alternative method using bundle info for app icon
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String] {
            
            for iconName in iconFiles.reversed() {
                if let icon = UIImage(named: iconName) {
                    return icon
                }
            }
        }
        
        return nil
    }
}

#Preview {
    SettingsView()
}