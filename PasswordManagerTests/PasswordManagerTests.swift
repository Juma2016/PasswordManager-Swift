//
//  PasswordManagerTests.swift
//  PasswordManagerTests
//
//  Created by Mario Shenouda on 23.11.26.
//


import Testing
import Security
@testable import PasswordManager

@MainActor
struct PasswordManagerTests {

    @Test func validInputIsAccepted() {
        #expect(VaultModel.isValidInput(title: "GitHub", password: "geheim123") == true)
    }

    @Test func emptyTitleOrPasswordIsRejected() {
        #expect(VaultModel.isValidInput(title: "", password: "geheim123") == false)
        #expect(VaultModel.isValidInput(title: "   ", password: "geheim123") == false)
        #expect(VaultModel.isValidInput(title: "GitHub", password: "") == false)
    }

    @Test func statusCodesMapToExpectedMessages() {
        let canceled = VaultModel.errorMessage(for: errSecUserCanceled)
        let authFailed = VaultModel.errorMessage(for: errSecAuthFailed)
        let notFound = VaultModel.errorMessage(for: errSecItemNotFound)

        #expect(canceled.contains("abgebrochen"))
        #expect(authFailed.contains("Face ID"))
        #expect(notFound.contains("Kein Eintrag"))
    }

    @Test func keychainErrorsReturnReadableDescriptions() {
        let invalidData = VaultModel.describe(KeychainError.invalidData)
        let accessControl = VaultModel.describe(KeychainError.accessControl)

        #expect(!invalidData.isEmpty)
        #expect(!accessControl.isEmpty)
    }
}
