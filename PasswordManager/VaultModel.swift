//
//  VaultModel.swift
//  PasswordManager
//
//  UI-Zustand auf dem MainActor. Keychain-Zugriffe im Store (actor).
//

import Foundation
import Observation
import Security

enum DetailStatus {
    case idle
    case unlocked
    case canceled
    case authFailed
    case error(String)
}

@MainActor @Observable
final class VaultModel {
    var entries: [PasswordEntry] = []
    var isBusy = false
    var errorMessage = ""

    // Zustand für die Detailansicht
    var shownPassword = ""
    var detailStatus: DetailStatus = .idle

    let store = KeychainStore()

    // Alle Einträge (Titel + Benutzername) laden
    func loadEntries() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = ""
        do {
            entries = try await store.loadEntries()
        } catch {
            errorMessage = Self.describe(error)
        }
    }

    // Neuen Eintrag speichern
    func save(title: String, username: String, password: String) async -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidInput(title: cleanTitle, password: password) else {
            errorMessage = "Titel und Passwort dürfen nicht leer sein."
            return false
        }
        guard !isBusy else { return false }
        isBusy = true
        defer { isBusy = false }
        errorMessage = ""
        do {
            try await store.saveProtected(password, title: cleanTitle, username: cleanUsername)
            entries = try await store.loadEntries()
            return true
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    // Passwort über die Keychain mit Face ID laden
    func loadPassword(for title: String) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        shownPassword = ""
        detailStatus = .idle
        do {
            shownPassword = try await store.loadProtected(account: title)
            detailStatus = .unlocked
        } catch KeychainError.status(errSecUserCanceled) {
            detailStatus = .canceled
        } catch KeychainError.status(errSecAuthFailed) {
            detailStatus = .authFailed
        } catch {
            detailStatus = .error(Self.describe(error))
        }
    }

    func hidePassword() {
        shownPassword = ""
        detailStatus = .idle
    }

    // Eintrag löschen
    func delete(title: String) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        defer { isBusy = false }
        errorMessage = ""
        do {
            try await store.delete(account: title)
            shownPassword = ""
            detailStatus = .idle
            entries = try await store.loadEntries()
            return true
        } catch {
            errorMessage = Self.describe(error)
            return false
        }
    }

    // Prüft ob Titel und Passwort ausgefüllt sind
    static func isValidInput(title: String, password: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    // Ordnet Keychain-Statuscodes eine verständliche Meldung zu
    static func errorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecUserCanceled:
            return "Face ID abgebrochen. Das Passwort bleibt verborgen."
        case errSecAuthFailed:
            return "Face ID fehlgeschlagen oder neu eingerichtet. Der Eintrag ist eventuell nicht mehr lesbar."
        case errSecItemNotFound:
            return "Kein Eintrag in der Keychain gefunden."
        case errSecDuplicateItem:
            return "Eintrag existiert bereits."
        case errSecInteractionNotAllowed:
            return "Gerät ist gesperrt. Bitte später erneut versuchen."
        default:
            let text = SecCopyErrorMessageString(status, nil) as String? ?? "Unbekannter Fehler"
            return "\(text) (\(status))"
        }
    }

    static func describe(_ error: Error) -> String {
        guard let keychainError = error as? KeychainError else {
            return error.localizedDescription
        }
        switch keychainError {
        case .status(let status):
            return errorMessage(for: status)
        case .invalidData:
            return "Die gespeicherten Daten sind kein gültiger Text."
        case .accessControl:
            return "Die Zugriffsregel ließ sich nicht erzeugen."
        }
    }
}
