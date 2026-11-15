import Foundation
import Security

enum KeychainError: LocalizedError {
    case unhandled(OSStatus)
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Kein Eintrag im Schlüsselbund gefunden."
        case .unhandled(let status):
            let detail = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
            return "Schlüsselbund-Fehler: \(detail)"
        }
    }
}

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = Constants.Keychain.service

    func saveToken(_ token: String) throws {
        try save(token, account: Constants.Keychain.tokenAccount)
    }

    func getToken() throws -> String {
        try get(account: Constants.Keychain.tokenAccount)
    }

    func deleteToken() throws {
        try delete(account: Constants.Keychain.tokenAccount)
    }

    func saveTankerkoenigAPIKey(_ key: String) throws {
        try save(key, account: Constants.Keychain.tankerkoenigAPIKeyAccount)
    }

    func getTankerkoenigAPIKey() throws -> String {
        try get(account: Constants.Keychain.tankerkoenigAPIKeyAccount)
    }

    func deleteTankerkoenigAPIKey() throws {
        try delete(account: Constants.Keychain.tankerkoenigAPIKeyAccount)
    }

    func saveWolAgentToken(_ token: String) throws {
        try save(token, account: Constants.Keychain.wolAgentTokenAccount)
    }

    func getWolAgentToken() throws -> String {
        try get(account: Constants.Keychain.wolAgentTokenAccount)
    }

    func deleteWolAgentToken() throws {
        try delete(account: Constants.Keychain.wolAgentTokenAccount)
    }

    private func save(_ value: String, account: String) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(newItem as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    private func get(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }
            throw KeychainError.unhandled(status)
        }
        return value
    }

    private func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }
}
