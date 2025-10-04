import SwiftUI

struct PasscodeSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var passcodeManager = AppPasscodeManager.shared
    
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var isConfirming = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    let onPasscodeSet: () -> Void
    
    private let passcodeLength = 4
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text(isConfirming ? "Confirm Passcode" : "Set App Passcode")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(isConfirming ? "Enter your passcode again" : "Choose a 4-digit passcode for app lock")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 24) {
                    // Passcode dots
                    HStack(spacing: 16) {
                        ForEach(0..<passcodeLength, id: \.self) { index in
                            Circle()
                                .fill(index < currentPasscode.count ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 16, height: 16)
                        }
                    }
                    
                    // Number pad
                    VStack(spacing: 16) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 40) {
                                ForEach(1...3, id: \.self) { col in
                                    let number = row * 3 + col
                                    NumberButton(number: "\(number)") {
                                        addDigit("\(number)")
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 40) {
                            // Empty space
                            Color.clear
                                .frame(width: 60, height: 60)
                            
                            NumberButton(number: "0") {
                                addDigit("0")
                            }
                            
                            Button(action: deleteDigit) {
                                Image(systemName: "delete.left")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    resetPasscodeEntry()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var currentPasscode: String {
        isConfirming ? confirmPasscode : passcode
    }
    
    private func addDigit(_ digit: String) {
        if isConfirming {
            if confirmPasscode.count < passcodeLength {
                confirmPasscode += digit
                if confirmPasscode.count == passcodeLength {
                    verifyAndSavePasscode()
                }
            }
        } else {
            if passcode.count < passcodeLength {
                passcode += digit
                if passcode.count == passcodeLength {
                    moveToConfirmation()
                }
            }
        }
    }
    
    private func deleteDigit() {
        if isConfirming {
            if !confirmPasscode.isEmpty {
                confirmPasscode.removeLast()
            }
        } else {
            if !passcode.isEmpty {
                passcode.removeLast()
            }
        }
    }
    
    private func moveToConfirmation() {
        withAnimation {
            isConfirming = true
        }
    }
    
    private func verifyAndSavePasscode() {
        if passcode == confirmPasscode {
            if passcodeManager.setPasscode(passcode) {
                onPasscodeSet()
                dismiss()
            } else {
                showError("Failed to save passcode. Please try again.")
            }
        } else {
            showError("Passcodes don't match. Please try again.")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func resetPasscodeEntry() {
        passcode = ""
        confirmPasscode = ""
        isConfirming = false
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

#Preview {
    PasscodeSetupView {
        print("Passcode set!")
    }
}