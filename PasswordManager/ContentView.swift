//
//  ContentView.swift
//  PasswordManager
//
//  Created by Mario Shenouda on 16.11.26.
//

import SwiftUI

struct ContentView: View {
    @State private var model = VaultModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if !model.errorMessage.isEmpty {
                    Text(model.errorMessage)
                        .foregroundStyle(.red)
                }

                if model.entries.isEmpty {
                    Text("Noch keine Einträge gespeichert.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.entries) { entry in
                        NavigationLink {
                            DetailView(entry: entry, model: model)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(entry.title)
                                        .font(.headline)
                                    Text(entry.username.isEmpty ? "-" : entry.username)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Passwörter")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEntryView(model: model)
            }
            .task {
                await model.loadEntries()
            }
        }
    }
}

#Preview {
    ContentView()
}
