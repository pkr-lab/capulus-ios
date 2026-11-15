import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                KeychainSecretSection(
                    title: "carplay-api Token",
                    placeholder: "Bearer token",
                    footer: "Erzeugt per kubeseal beim Einrichten von carplay-api — siehe capulus-core/3-apps-workloads/300d0-carplay-api.md \"Ersteinrichtung\" im Repo pkr-lab-docs.",
                    noun: .token,
                    read: KeychainService.shared.getToken,
                    save: KeychainService.shared.saveToken,
                    delete: KeychainService.shared.deleteToken
                )

                KeychainSecretSection(
                    title: "Tankerkönig API-Key",
                    placeholder: "API-Key",
                    footer: "Für die Tankstellen-Seite im Alltag-Modus. Kostenlosen Key registrieren: creativecommons.tankerkoenig.de",
                    noun: .key,
                    read: KeychainService.shared.getTankerkoenigAPIKey,
                    save: KeychainService.shared.saveTankerkoenigAPIKey,
                    delete: KeychainService.shared.deleteTankerkoenigAPIKey
                )

                KeychainSecretSection(
                    title: "Vereinsheim-WoL-Agent-Token",
                    placeholder: "Bearer token",
                    footer: "Auf dem Pi selbst erzeugt (capulus-ansible/3-apps-workloads/30020-vereinsheim-alarmmonitor.md im Repo pkr-lab-docs, Abschnitt \"Wake-on-LAN für den Windows-PC\") — auslesen mit: ssh pela@vereinsheim-alarmmonitor sudo cat /etc/banana-pi-wol-agent/token",
                    noun: .token,
                    read: KeychainService.shared.getWolAgentToken,
                    save: KeychainService.shared.saveWolAgentToken,
                    delete: KeychainService.shared.deleteWolAgentToken
                )
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

private enum SecretNoun {
    case token
    case key

    var stored: String {
        switch self {
        case .token: return "Es ist bereits ein Token gespeichert."
        case .key: return "Es ist bereits ein Key gespeichert."
        }
    }

    var saved: String {
        switch self {
        case .token: return "Token gespeichert."
        case .key: return "Key gespeichert."
        }
    }

    var removed: String {
        switch self {
        case .token: return "Token entfernt."
        case .key: return "Key entfernt."
        }
    }

    var removeLabel: String {
        switch self {
        case .token: return "Gespeichertes Token entfernen"
        case .key: return "Gespeicherten Key entfernen"
        }
    }
}

private struct KeychainSecretSection: View {
    let title: String
    let placeholder: String
    let footer: String
    let noun: SecretNoun
    let read: () throws -> String
    let save: (String) throws -> Void
    let delete: () throws -> Void

    @State private var value = ""
    @State private var statusMessage: String?

    var body: some View {
        Section {
            SecureField(placeholder, text: $value)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        } header: {
            Text(title)
        } footer: {
            Text(footer)
        }

        Section {
            Button("In Keychain speichern") { store() }
                .disabled(value.isEmpty)
            Button(noun.removeLabel, role: .destructive) { remove() }
        }
        .onAppear {
            if (try? read()) != nil {
                statusMessage = noun.stored
            }
        }

        if let statusMessage {
            Section {
                Text(statusMessage)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func store() {
        do {
            try save(value)
            statusMessage = noun.saved
            value = ""
        } catch {
            statusMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func remove() {
        do {
            try delete()
            statusMessage = noun.removed
        } catch {
            statusMessage = "Entfernen fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
