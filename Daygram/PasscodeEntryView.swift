import SwiftUI

struct PasscodeEntryView: View {
    @StateObject private var passcodeManager = AppPasscodeManager.shared
    
    @State private var enteredPasscode = ""
    @State private var showingError = false
    @State private var attemptCount = 0
    @State private var isShaking = false
    
    let title: String
    let subtitle: String
    let onSuccess: () -> Void
    let onCancel: (() -> Void)?
    
    init(title: String = "Enter Passcode", subtitle: String = "Enter your 4-digit passcode", onSuccess: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }
    
    private let passcodeLength = 4
    private let maxAttempts = 5
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if attemptCount > 0 {
                        Text("Incorrect passcode. \(maxAttempts - attemptCount) attempts remaining.")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            VStack(spacing: 24) {
                // Passcode dots
                HStack(spacing: 16) {
                    ForEach(0..<passcodeLength, id: \.self) { index in
                        Circle()
                            .fill(index < enteredPasscode.count ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }
                .offset(x: isShaking ? -8 : 0)
                .animation(isShaking ? Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true) : .default, value: isShaking)
                
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
                        // Cancel button (if provided)
                        if let onCancel = onCancel {
                            Button("Cancel") {
                                onCancel()
                            }
                            .foregroundColor(.blue)
                            .frame(width: 60, height: 60)
                        } else {
                            Color.clear
                                .frame(width: 60, height: 60)
                        }
                        
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
        .alert("Too Many Attempts", isPresented: $showingError) {
            Button("OK") {
                onCancel?()
            }
        } message: {
            Text("You have exceeded the maximum number of passcode attempts. Please try again later.")
        }
    }
    
    private func addDigit(_ digit: String) {
        if enteredPasscode.count < passcodeLength {
            enteredPasscode += digit
            
            if enteredPasscode.count == passcodeLength {
                verifyPasscode()
            }
        }
    }
    
    private func deleteDigit() {
        if !enteredPasscode.isEmpty {
            enteredPasscode.removeLast()
        }
    }
    
    private func verifyPasscode() {
        if passcodeManager.verifyPasscode(enteredPasscode) {
            onSuccess()
        } else {
            attemptCount += 1
            
            if attemptCount >= maxAttempts {
                showingError = true
            } else {
                // Shake animation and reset
                isShaking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShaking = false
                    enteredPasscode = ""
                }
            }
        }
    }
}

#Preview {
    PasscodeEntryView(
        onSuccess: {
            print("Passcode correct!")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}