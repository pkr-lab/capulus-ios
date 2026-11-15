import Foundation

struct AppUpdate: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let currentVersion: String?
    let latestVersion: String?
    let latestURL: URL?
    let hasUpdate: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case currentVersion = "current_version"
        case latestVersion = "latest_version"
        case latestURL = "latest_url"
        case hasUpdate = "has_update"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? name
        currentVersion = try container.decodeIfPresent(String.self, forKey: .currentVersion)
        latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion)
        latestURL = try? container.decodeIfPresent(URL.self, forKey: .latestURL)
        hasUpdate = try container.decodeIfPresent(Bool.self, forKey: .hasUpdate)
    }
}

struct UpdatesResponse: Codable, Equatable {
    let updatedAt: Int64
    let repos: [AppUpdate]

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case repos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updatedAt = try container.decodeIfPresent(Int64.self, forKey: .updatedAt) ?? 0
        repos = try container.decodeIfPresent([AppUpdate].self, forKey: .repos) ?? []
    }
}
