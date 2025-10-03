import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @AppStorage("requireAuthentication") private var requireAuthentication = false
    
    var body: some View {
        if requireAuthentication && !authManager.isAuthenticated {
            authenticationScreen
        } else {
            CalendarView()
                .onAppear {
                    if requireAuthentication && !authManager.isAuthenticated {
                        Task {
                            await authManager.authenticate()
                        }
                    }
                }
        }
    }
    
    private var authenticationScreen: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                VStack(spacing: 8) {
                    Text("Daygram")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your private baby memories")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 20) {
                if authManager.biometricType != .none {
                    Button(action: {
                        Task {
                            await authManager.authenticate()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: authManager.biometricIcon)
                                .font(.title2)
                            Text("Unlock with \(authManager.biometricName)")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Button(action: {
                    Task {
                        await authManager.authenticateWithPasscode()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .font(.title2)
                        Text("Unlock with Passcode")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if let error = authManager.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            Button(action: {
                requireAuthentication = false
            }) {
                Text("Skip Authentication")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            authManager.checkBiometricAvailability()
        }
    }
}

#Preview {
    AuthenticationView()
        .modelContainer(for: MemoryEntry.self, inMemory: true)
}