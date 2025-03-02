import Security
import Foundation
struct KeychainHelper {
    static func save(userIdentifier: String) {
        let data = Data(userIdentifier.utf8)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "appleUserIdentifier",
            kSecValueData: data
        ] as CFDictionary
        SecItemDelete(query) // Remove existing entry
        SecItemAdd(query, nil) // Save new entry
    }
    
    static func getUserIdentifier() -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "appleUserIdentifier",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    static func deleteUserIdentifier() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "appleUserIdentifier"
        ] as CFDictionary
        SecItemDelete(query)
    }
}
