//
//  KeychainStore.swift
//  PasswordManager
//

import Foundation
import Security
import LocalAuthentication

struct PasswordEntry: Identifiable, Sendable {
    var id: String { title }
    let title: String
    let username: String
}

enum KeychainError: Error {
    case status(OSStatus)   // Die Keychain meldet einen Code, z. B. -25300
    case invalidData        // Die Bytes sind kein UTF-8-Text
    case accessControl      // Die Face-ID-Regel ließ sich nicht erzeugen
}

actor KeychainStore {
    private let service = "at.fhj.nmd.passwordmanager"

    // Klasse + Service + Account machen einen Eintrag eindeutig
    private func baseQuery(account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private func string(from result: CFTypeRef?) throws -> String {
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { throw KeychainError.invalidData }
        return value
    }

    // Zugriffsregel für Face ID mit .biometryCurrentSet
    private func faceIDAccess() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            _ = error?.takeRetainedValue()
            throw KeychainError.accessControl
        }
        return access
    }

    // Speichert einen geschützten Eintrag ohne Face-ID-Abfrage beim Anlegen
    func saveProtected(_ password: String, title: String, username: String) throws {
        var add = baseQuery(account: title)
        let access = try faceIDAccess()
        add[kSecAttrAccessControl as String] = access
        add[kSecAttrLabel as String] = username
        add[kSecValueData as String] = Data(password.utf8)

        let status = SecItemAdd(add as CFDictionary, nil)
        if status == errSecDuplicateItem {
            try update(password, title: title, username: username)
        } else if status != errSecSuccess {
            throw KeychainError.status(status)
        }
    }

    // Vorhandenen Eintrag bei errSecDuplicateItem (-25299) aktualisieren
    private func update(_ password: String, title: String, username: String) throws {
        let query = baseQuery(account: title)
        let changes: [String: Any] = [
            kSecAttrLabel as String: username,
            kSecValueData as String: Data(password.utf8)
        ]
        let status = SecItemUpdate(query as CFDictionary, changes as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
    }

    // Liste laden: nur Titel und Benutzername, nie das Passwort
    func loadEntries() throws -> [PasswordEntry] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard let items = result as? [[String: Any]] else {
            return []
        }

        var entries: [PasswordEntry] = []
        for item in items {
            if let title = item[kSecAttrAccount as String] as? String {
                let username = item[kSecAttrLabel as String] as? String ?? ""
                entries.append(PasswordEntry(title: title, username: username))
            }
        }
        entries.sort { $0.title < $1.title }
        return entries
    }

    // Suchanfrage mit LAContext für die Face-ID-Abfrage durch die Keychain
    private func protectedQuery(account: String) -> [String: Any] {
        let context = LAContext()
        context.localizedReason = "Passwort anzeigen"
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = context
        return query
    }

    // Liest das Passwort für einen Eintrag. Die Keychain zeigt die Face-ID-Abfrage.
    func loadProtected(account: String) async throws -> String {
        #if targetEnvironment(simulator)
        // Nur für den Simulator, weil der Simulator die Keychain-Regel nicht selbst durchsetzt
        let simContext = LAContext()
        do {
            _ = try await simContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Passwort anzeigen"
            )
        } catch let error as LAError {
            if error.code == .userCancel || error.code == .systemCancel || error.code == .appCancel {
                throw KeychainError.status(errSecUserCanceled)
            } else {
                throw KeychainError.status(errSecAuthFailed)
            }
        } catch {
            throw KeychainError.status(errSecAuthFailed)
        }
        #endif

        let query = protectedQuery(account: account)
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        return try string(from: result)
    }

    // Eintrag aus der Keychain löschen
    func delete(account: String) throws {
        let query = baseQuery(account: account)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.status(status)
        }
    }
}
