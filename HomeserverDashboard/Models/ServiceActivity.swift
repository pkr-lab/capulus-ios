import Foundation

struct ServiceActivity: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let requestsPerSecond: Double

    enum CodingKeys: String, CodingKey {
        case id, name
        case requestsPerSecond = "requests_per_second"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? name
        requestsPerSecond = try container.decodeIfPresent(Double.self, forKey: .requestsPerSecond) ?? 0
    }
}
