# CLAUDE.md — Arbeitsregeln für capulus-ios

SwiftUI-App „Homeserver Dashboard“ für iPhone und iPad: Alarme, Host-Metriken und Dienststatus des Capulus-Homelabs sowie Helligkeit und Wake/Shutdown der Server. Das Backend ist `carplay-api` in [capulus-core](https://github.com/pkr-lab/capulus-core). Sprache im Repo ist **Deutsch** (Docs, Commit-Beschreibungen, PR-Texte). Regeln wie in capulus-core.

---

## Harte Regeln

- **Keine neuen Kommentare im Code.** Gilt für Swift, `project.yml` und Workflows. Bestehende Kommentare bleiben, bis die Stelle ohnehin überarbeitet wird; dann die Begründung ins Doc verschieben. Einzige Ausnahme: der Versions-Kommentar `# vX.Y.Z` hinter der Commit-SHA in `uses:`-Zeilen der Workflows (Renovate und Dependabot lesen ihn).
- **Doku liegt nicht in diesem Repo, sondern in [pkr-lab-docs](https://github.com/pkr-lab/pkr-lab-docs)** unter `capulus/capulus-ios/` (Einstieg `entwicklung.md`). Jede Codeänderung bekommt dort einen PR. Hintergründe zur API: `capulus/capulus-core/6-hintergruende/60080-carplay-api-und-ios-app.md`. Konventionen stehen in der `CLAUDE.md` von pkr-lab-docs.
- **`project.yml` ist die Quelle der Wahrheit.** `HomeserverDashboard.xcodeproj` und `HomeserverDashboard/Info.plist` sind generiert (`xcodegen generate`) und in `.gitignore`; nie von Hand ändern oder committen. Neue Quelldateien unter `HomeserverDashboard/` nimmt XcodeGen automatisch auf.
- **Niemals Klartext-Secrets committen.** API-Token, Tankerkönig-Key und WoL-Agent-Token liegen ausschließlich im Keychain (`KeychainService`) und werden in den Einstellungen eingegeben. gitleaks läuft in der CI (`.gitleaks.toml`).
- **Die Root-CA `Resources/homeserver-root-ca.pem` nie ändern.** Quelle der Wahrheit ist `pki/` in capulus-core, die CI vergleicht beide Dateien.
- **Nie direkt auf `main` arbeiten.** `main` ist geschützt, Änderungen gehen nur per PR hinein. Steht das Arbeitsverzeichnis auf `main`, vor der ersten Änderung einen neuen Branch anlegen (`git switch -c <typ>/<kurzbeschreibung>`, z. B. `feat/backup-retention`, `fix/ca-pin`) und nur dort arbeiten. Den Branch legt Claude an, Commit, Push und PR macht der Nutzer.
- Keine Drittbibliotheken, kein Swift Package (bewusste Entscheidung, siehe `entwicklung.md`).

---

## Wo was liegt

| Pfad | Inhalt |
|---|---|
| `HomeserverDashboard/HomeserverDashboardApp.swift` | Einstiegspunkt |
| `HomeserverDashboard/Models/` | `Codable`-Modelle, tolerant decodierend (Standardwerte für fehlende Listen, Rückfall für unbekannte Enum-Strings) |
| `HomeserverDashboard/Services/` | API-Clients (`URLSession`, `async/await`), Keychain, Standort, Tailscale-Erkennung |
| `HomeserverDashboard/ViewModels/` | `DashboardViewModel.shared`, `PowerViewModel.shared` (`@MainActor`, `ObservableObject`) |
| `HomeserverDashboard/Views/` | SwiftUI-Ansichten; die Ansichten des Alltag-Modus halten ihren Zustand in `@State` |
| `HomeserverDashboard/Utilities/` | `Constants` (URLs, Keychain-Schlüssel), `MTLSDelegate`, Theme, Formatter |
| `project.yml` | XcodeGen-Projektdefinition (iOS 15, Swift 5, Info.plist-Werte, Berechtigungstexte) |
| `Resources/` | Root-CA als Bundle-Ressource |

---

## Prüfen vor dem Commit

Die CI (`.github/workflows/ci.yml`) hat drei Pflicht-Jobs: `xcodegen` + `xcodebuild` (macOS-Runner), Root-CA-Vergleich mit capulus-core, gitleaks. Zusätzlich läuft CodeQL.

```bash
brew install xcodegen
xcodegen generate
xcodebuild build -project HomeserverDashboard.xcodeproj -target HomeserverDashboard CODE_SIGNING_ALLOWED=NO
```

Auf Linux (auch in der Sandbox) gibt es weder Xcode noch Swift-Toolchain für iOS. Dann den Build-Befehl dem Nutzer nennen und Änderungen besonders sorgfältig gegen die vorhandenen Typen prüfen (kein Compiler-Feedback).

---

## Code-Stil

- MVVM light: Ansichten beobachten die Singleton-ViewModels; Clients sind einfache Klassen ohne eigenen Zustand der Oberfläche.
- Netzwerk zum Cluster und zum WoL-Agent läuft über `MTLSDelegate`, der das Serverzertifikat gegen die Root-CA aus dem Bundle prüft; keine pauschalen Ausnahmen für Zertifikatsfehler.
- URLs und Keychain-Schlüssel stehen in `Constants`, nicht verstreut in Clients.
- Neue Berechtigungen (Standort etc.) mit deutschem Begründungstext in `project.yml` unter `info.properties`.
- Neue API-Felder tolerant decodieren: ältere Backends dürfen die App nicht zum Absturz bringen.

---

## Commits und PRs

- **Claude committet und pusht nicht.** Commits, Pushes und PRs macht ausschließlich der Nutzer. Änderungen nur im Arbeitsverzeichnis vorbereiten, am Ende kurz zusammenfassen und einen passenden Commit-Text vorschlagen. Ausnahme nur, wenn der Nutzer es in der jeweiligen Anfrage ausdrücklich verlangt.
- Conventional Commits mit Scope = Bereich, Beschreibung auf Deutsch: `feat(alltag): …`, `fix(power): …`, `docs(…): …`. Typen: feat fix docs chore refactor test ci build perf style revert.
  `feat`/`fix` lösen über semantic-release ein Release aus (zentraler Workflow in `pkr-lab/.github`, CHANGELOG.md und Tag `vX.Y.Z`). Der Commitlint-Check läuft auf PRs; lokal prüft `git config core.hooksPath .githooks` das Format.
- Ein PR = eine Änderung inkl. zugehöriger Doku. Renovate-PRs nicht manuell nachbauen.
