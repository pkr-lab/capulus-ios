import Foundation

struct Alert: Codable, Identifiable, Equatable {
    let id: String
    let topic: String
    let title: String
    let message: String
    let time: Int64
    let level: AlertLevel
    let pollId: String?

    enum CodingKeys: String, CodingKey {
        case id, topic, title, message, time, level
        case pollId = "poll_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topic = try container.decodeIfPresent(String.self, forKey: .topic) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        time = try container.decodeIfPresent(Int64.self, forKey: .time) ?? 0
        level = try container.decodeIfPresent(AlertLevel.self, forKey: .level) ?? .info
        pollId = try container.decodeIfPresent(String.self, forKey: .pollId)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "\(topic)-\(time)-\(title)"
    }
}

enum AlertLevel: String, Codable {
    case critical
    case warning
    case info

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AlertLevel(rawValue: raw) ?? .info
    }
}
