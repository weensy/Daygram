import SwiftUI

struct SettingsView: View {
    @AppStorage("requireAuthentication") private var requireAuthentication = false
    @StateObject private var authManager = BiometricAuthManager()
    @Environment(\.dismiss) private var dismiss
    
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
                    Toggle(isOn: $requireAuthentication) {
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
                                } else {
                                    Text("Require passcode to open app")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .disabled(authManager.biometricType == .none)
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
    }
}

#Preview {
    SettingsView()
}