//
//  AddEntryView.swift
//  PasswordManager
//
//  Created by Mario Shenouda on 20.11.26.
//

import SwiftUI

struct AddEntryView: View {
    var model: VaultModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var username: String
    @State private var password = ""

    init(model: VaultModel, initialTitle: String = "", initialUsername: String = "") {
        self.model = model
        _title = State(initialValue: initialTitle)
        _username = State(initialValue: initialUsername)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titel", text: $title)
                    TextField("Benutzername", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Passwort", text: $password)
                } footer: {
                    Text("Das Passwort wird mit Face ID geschützt. Ein Gerätecode muss eingerichtet sein.")
                }

                if !model.errorMessage.isEmpty {
                    Section {
                        Text(model.errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Speichern") {
                        Task {
                            let ok = await model.save(
                                title: title,
                                username: username,
                                password: password
                            )
                            if ok {
                                dismiss()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!VaultModel.isValidInput(title: title, password: password) || model.isBusy)
                }
            }
            .navigationTitle("Neuer Eintrag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Mit Hilfe von AI
#Preview {
    AddEntryView(model: VaultModel())
}
