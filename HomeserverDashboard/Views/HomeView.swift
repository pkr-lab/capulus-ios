import SwiftUI

struct HomeView: View {
    @ObservedObject private var viewModel = DashboardViewModel.shared
    @ObservedObject private var connectivity = TailscaleConnectivity.shared
    @State private var selectedService: ServiceStatus?

    var body: some View {
        NavigationView {
            ScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !connectivity.isLikelyReachable || viewModel.error != nil {
                            OfflineBanner(detail: viewModel.error)
                        }

                        HostCardsView(hosts: viewModel.dashboard?.hosts ?? [])

                        StatusGridView(
                            statuses: viewModel.dashboard?.status ?? [],
                            onSelect: { selectedService = $0 }
                        )

                        ServiceActivityCard(activity: viewModel.dashboard?.serviceActivity ?? [])

                        UpdatesCard(updates: viewModel.appUpdates, error: viewModel.updatesError)

                        if viewModel.isLoading {
                            Text("Aktualisiere …")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if let lastUpdate = viewModel.lastUpdate {
                            Text("Aktualisiert \(FormatterHelper.relativeTime(Int64(lastUpdate.timeIntervalSince1970)))")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Homeserver")
            .refreshable {
                async let dashboard: Void = viewModel.fetchDashboard()
                async let updates: Void = viewModel.fetchUpdates()
                _ = await (dashboard, updates)
            }
            .task {
                viewModel.startAutoRefresh()
                await viewModel.fetchUpdates()
            }
            .sheet(item: Binding(
                get: { selectedService.map(ServiceStatusDetailItem.init) },
                set: { selectedService = $0?.status }
            )) { item in
                DetailView(kind: .service(item.status))
            }
        }
    }
}

private struct ServiceStatusDetailItem: Identifiable {
    let status: ServiceStatus
    var id: String { status.id }
}

private struct ServiceActivityCard: View {
    let activity: [ServiceActivity]

    private var sorted: [ServiceActivity] {
        activity.sorted { $0.requestsPerSecond > $1.requestsPerSecond }
    }

    private var maxRate: Double {
        max(sorted.first?.requestsPerSecond ?? 0, 0.1)
    }

    var body: some View {
        SectionCard(title: "Dienst-Aktivität", systemImage: "chart.bar.fill") {
            if sorted.isEmpty {
                NoDataText()
            } else {
                VStack(spacing: 10) {
                    ForEach(sorted) { entry in
                        ServiceActivityRow(entry: entry, maxRate: maxRate)
                    }
                }

                Text("Traefik-Request-Rate (5-Min-Mittel) je Dienst — Näherung für Aktivität, keine Nutzerzahl.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

private struct ServiceActivityRow: View {
    let entry: ServiceActivity
    let maxRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(String(format: "%.2f req/s", entry.requestsPerSecond))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textMuted)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: Theme.radiusSmall / 2, style: .continuous)
                    .fill(Theme.glassBackgroundStrong)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Theme.radiusSmall / 2, style: .continuous)
                            .fill(Theme.accentLight)
                            .frame(width: geo.size.width * min(entry.requestsPerSecond / maxRate, 1))
                    }
            }
            .frame(height: 8)
        }
    }
}

private struct UpdatesCard: View {
    let updates: [AppUpdate]
    let error: String?

    private var available: [AppUpdate] { updates.filter { $0.hasUpdate == true } }
    private var unknown: [AppUpdate] { updates.filter { $0.hasUpdate == nil } }

    var body: some View {
        if !updates.isEmpty || error != nil {
            SectionCard(title: "Updates", systemImage: "arrow.down.circle.fill") {
                if let error {
                    Text("Updates konnten nicht geladen werden: \(error)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.statusWarning)
                } else if available.isEmpty {
                    Text("Alle Apps aktuell.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                } else {
                    VStack(spacing: 8) {
                        ForEach(available) { update in
                            UpdateRow(update: update)
                        }
                    }
                }

                if !unknown.isEmpty {
                    Text("Kein bekannter aktueller Stand für \(unknown.map(\.name).joined(separator: ", ")) — currentVersion in github-release-watcher/values.yaml nachtragen.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
}

private struct UpdateRow: View {
    let update: AppUpdate

    var body: some View {
        Group {
            if let url = update.latestURL {
                Link(destination: url) { content }
            } else {
                content
            }
        }
        .padding(10)
        .glassTile()
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(update.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(update.currentVersion ?? "?") → \(update.latestVersion ?? "?")")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Image(systemName: "arrow.up.circle.fill")
                .foregroundStyle(Theme.statusWarning)
        }
    }
}

private struct OfflineBanner: View {
    let detail: String?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "wifi.slash")
            VStack(alignment: .leading, spacing: 2) {
                Text("Homeserver nicht erreichbar — zeige letzten bekannten Stand.")
                    .font(.system(size: 13))
                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.statusWarning.opacity(0.18))
        .foregroundStyle(Theme.statusWarning)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
    }
}
