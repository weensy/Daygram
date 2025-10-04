import SwiftUI

struct SettingsView: View {
    @AppStorage("requireAuthentication") private var requireAuthentication = false
    @StateObject private var authManager = BiometricAuthManager()
    @StateObject private var passcodeManager = AppPasscodeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPasscodeSetup = false
    @State private var showingPasscodeVerification = false
    @State private var showingPasscodeDisableConfirmation = false
    @State private var isAuthenticating = false
    @State private var verificationPurpose: VerificationPurpose = .changePasscode
    
    enum VerificationPurpose {
        case changePasscode
        case disableAppLock
        case enableAppLock
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .foregroundColor(.pink)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daygram")
                                .font(.headline)
                            Text("Private baby photo diary")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Privacy & Security") {
                    Toggle(isOn: Binding(
                        get: { requireAuthentication },
                        set: { newValue in
                            if newValue {
                                enableAppLock()
                            } else {
                                disableAppLock()
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: authManager.biometricIcon)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Lock")
                                    .font(.body)
                                
                                if authManager.biometricType != .none {
                                    Text("Require \(authManager.biometricName) to open app")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if passcodeManager.hasPasscode {
                                    Text("Require app passcode to open app")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Set up app passcode to enable lock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Show passcode change option if app passcode is set
                    if passcodeManager.hasPasscode {
                        Button(action: {
                            verificationPurpose = .changePasscode
                            showingPasscodeVerification = true
                        }) {
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Change App Passcode")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("Update your 4-digit app passcode")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Data Storage")
                            Text("All photos and notes are stored locally on your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy First")
                            Text("No accounts, no cloud sync, no tracking")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
}

#Preview {
    SettingsView()
}