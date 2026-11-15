import Foundation

struct HostMetrics: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let online: Bool
    let cpu: Double
    let ram: Double
    let disk: Double
    let temperature: Double
    let uptime: String

    enum CodingKeys: String, CodingKey {
        case id, name, online, cpu, ram, disk, temperature, uptime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? name
        online = try container.decodeIfPresent(Bool.self, forKey: .online) ?? false
        cpu = try container.decodeIfPresent(Double.self, forKey: .cpu) ?? 0
        ram = try container.decodeIfPresent(Double.self, forKey: .ram) ?? 0
        disk = try container.decodeIfPresent(Double.self, forKey: .disk) ?? 0
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 0
        uptime = try container.decodeIfPresent(String.self, forKey: .uptime) ?? ""
    }
}
