import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    static let shared = BiometricAuthManager()

    @Published var isAuthenticated = false
    @Published var authError: String?
    @Published var biometricType: LABiometryType = .none
    @Published var canUseDeviceAuthentication = false
    @Published var canUseAppAuthentication = false

    private let context = LAContext()
    private let reason = "Unlock Daygram to view your private memories"

    private init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        // Check for biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
            if error?.code == LAError.biometryNotEnrolled.rawValue {
                authError = "No biometric authentication enrolled"
            }
        }
        
        // Check if device owner authentication (including passcode) is available
        canUseDeviceAuthentication = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        // Check if app-specific authentication is available (biometrics OR app passcode)
        canUseAppAuthentication = biometricType != .none || AppPasscodeManager.shared.hasPasscode
    }
    
    func authenticate() async {
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            await MainActor.run {
                authError = "Biometric authentication not available"
            }
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                if success {
                    isAuthenticated = true
                    authError = nil
                } else {
                    authError = "Authentication failed"
                }
            }
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
                isAuthenticated = false
            }
        }
    }
    
    func authenticateWithPasscode() async {
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            await MainActor.run {
                if success {
                    isAuthenticated = true
                    authError = nil
                } else {
                    authError = "Authentication failed"
                }
            }
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
                isAuthenticated = false
            }
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock"
        }
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Passcode"
        }
    }
    
    func authenticateWithAppPasscode(_ passcode: String) -> Bool {
        let success = AppPasscodeManager.shared.verifyPasscode(passcode)
        if success {
            isAuthenticated = true
            authError = nil
        } else {
            authError = "Incorrect passcode"
        }
        return success
    }
}