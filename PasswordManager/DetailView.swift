//
//  DetailView.swift
//  PasswordManager
//
//  Created by Mario Shenouda on 20.11.26.
//


import SwiftUI

struct DetailView: View {
    let entry: PasswordEntry
    var model: VaultModel

    @Environment(\.dismiss) private var dismiss
    @State private var showRecreateSheet = false

    var body: some View {
        Form {
            Section("Benutzername") {
                Text(entry.username.isEmpty ? "-" : entry.username)
            }

            Section("Passwort") {
                switch model.detailStatus {
                case .unlocked:
                    HStack {
                        Text(model.shownPassword)
                            .font(.body.monospaced())
                        Spacer()
                        Button("Verbergen") {
                            model.hidePassword()
                        }
                    }

                case .canceled:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Face ID abgebrochen")
                            .font(.headline)
                        Text("Das Passwort bleibt verborgen.")
                            .foregroundStyle(.secondary)
                        Button("Erneut versuchen") {
                            Task { await model.loadPassword(for: entry.title) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)

                case .authFailed:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eintrag nicht mehr lesbar")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("Face ID ist fehlgeschlagen oder wurde am Gerät neu eingerichtet. Das gespeicherte Passwort ist dann eventuell nicht mehr lesbar.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Eintrag neu anlegen") {
                            Task {
                                _ = await model.delete(title: entry.title)
                                showRecreateSheet = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Erneut versuchen") {
                            Task { await model.loadPassword(for: entry.title) }
                        }
                    }
                    .padding(.vertical, 4)

                case .error(let message):
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message)
                            .foregroundStyle(.red)
                        Button("Erneut versuchen") {
                            Task { await model.loadPassword(for: entry.title) }
                        }
                    }

                case .idle:
                    HStack {
                        Text("••••••••••••")
                        Spacer()
                        if model.isBusy {
                            ProgressView()
                        } else {
                            Button("Anzeigen") {
                                Task { await model.loadPassword(for: entry.title) }
                            }
                        }
                    }
                }
            }

            Section {
                Button("Eintrag löschen", role: .destructive) {
                    Task {
                        let ok = await model.delete(title: entry.title)
                        if ok {
                            dismiss()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(model.isBusy)
            }
        }
        .navigationTitle(entry.title)
        .task {
            await model.loadPassword(for: entry.title)
        }
        .onDisappear {
            model.hidePassword()
        }
        .sheet(isPresented: $showRecreateSheet, onDismiss: {
            dismiss()
        }) {
            AddEntryView(
                model: model,
                initialTitle: entry.title,
                initialUsername: entry.username
            )
        }
    }
}

// Mit hilfe von AI

#Preview {
    NavigationStack {
        DetailView(
            entry: PasswordEntry(title: "GitHub", username: "mhuber"),
            model: VaultModel()
        )
    }
}
