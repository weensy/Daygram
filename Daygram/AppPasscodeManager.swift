import Foundation
import Security
import CryptoKit

class AppPasscodeManager: ObservableObject {
    static let shared = AppPasscodeManager()
    
    @Published var hasPasscode: Bool = false
    
    private let service = "co.euca.daygram"
    private let account = "app_passcode"
    
    private init() {
        checkPasscodeExists()
    }
    
    func checkPasscodeExists() {
        hasPasscode = getStoredPasscodeHash() != nil
    }
    
    func setPasscode(_ passcode: String) -> Bool {
        let hash = hashPasscode(passcode)
        return storePasscodeHash(hash)
    }
    
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedHash = getStoredPasscodeHash() else {
            return false
        }
        
        let inputHash = hashPasscode(passcode)
        return inputHash == storedHash
    }
    
    func removePasscode() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        let success = status == errSecSuccess
        
        if success {
            hasPasscode = false
        }
        
        return success
    }
    
    private func hashPasscode(_ passcode: String) -> String {
        let data = Data(passcode.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func storePasscodeHash(_ hash: String) -> Bool {
        // First, delete any existing passcode
        removePasscode()
        
        let data = Data(hash.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        let success = status == errSecSuccess
        
        if success {
            hasPasscode = true
        }
        
        return success
    }
    
    private func getStoredPasscodeHash() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let hash = String(data: data, encoding: .utf8) {
                return hash
            }
        }
        
        return nil
    }
}