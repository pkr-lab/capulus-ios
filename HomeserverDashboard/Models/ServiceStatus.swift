import Foundation

struct ServiceStatus: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let status: ServiceState
    let ping: Int
    let uptime: Double
    let lastCheck: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, status, ping, uptime
        case lastCheck = "last_check"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? name
        status = try container.decodeIfPresent(ServiceState.self, forKey: .status) ?? .unknown
        ping = try container.decodeIfPresent(Int.self, forKey: .ping) ?? 0
        uptime = try container.decodeIfPresent(Double.self, forKey: .uptime) ?? 0
        lastCheck = try container.decodeIfPresent(Int64.self, forKey: .lastCheck) ?? 0
    }
}

enum ServiceState: String, Codable {
    case up
    case down
    case maintenance
    case paused
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ServiceState(rawValue: raw) ?? .unknown
    }
}
