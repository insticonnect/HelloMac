import Foundation
import Security

/// Small wrapper over the macOS Keychain for secrets that must never live in
/// the database (BYO OpenAI key, and later the DB encryption key).
enum Keychain {
    private static let service = "com.mitthuai.app"
    private static let legacyService = "com.hellomac.app"

    /// Secrets carried over from the pre-rebrand HelloMac keychain service.
    private static let migratableKeys = ["openai_api_key", "account_token", "device_id"]

    /// One-time copy of secrets from the old service name. Runs at most once
    /// (guarded by a marker item) and skips any key already set under the new
    /// service, so it never clobbers newer values.
    static func migrateLegacyIfNeeded() {
        guard read(service: service, key: "migrated_from_hellomac") == nil else { return }
        var moved = 0
        for key in migratableKeys {
            guard read(service: service, key: key) == nil,
                  let value = read(service: legacyService, key: key) else { continue }
            set(key, value)
            moved += 1
        }
        set("migrated_from_hellomac", "1")
        if moved > 0 { print("MitthuAI migration: carried over \(moved) keychain secret(s).") }
    }

    static func set(_ key: String, _ value: String?) {
        // Always clear the existing item first.
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(base as CFDictionary)

        guard let value = value, !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        return read(service: service, key: key)
    }

    private static func read(service svc: String, key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: svc,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}
