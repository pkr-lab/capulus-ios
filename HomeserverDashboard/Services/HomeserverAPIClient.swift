import Foundation

enum APIError: LocalizedError {
    case badResponse(statusCode: Int, message: String?)
    case decodingFailed(Error)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .badResponse(let statusCode, let message):
            return message ?? "Server antwortete mit HTTP \(statusCode)"
        case .decodingFailed(let error):
            return "Antwort konnte nicht gelesen werden: \(error.localizedDescription)"
        case .missingToken:
            return "Kein Token im Schlüsselbund gespeichert, bitte in den Einstellungen eintragen."
        }
    }
}

final class HomeserverAPIClient {
    static let shared = HomeserverAPIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL = Constants.apiBaseURL, session: URLSession = HomeserverHTTP.session) {
        self.baseURL = baseURL
        self.session = session
    }

    func getDashboard() async throws -> DashboardPayload {
        let (data, _) = try await request(method: "GET", path: "/api/dashboard")
        return try decode(DashboardPayload.self, from: data)
    }

    func getUpdates() async throws -> UpdatesResponse {
        let (data, _) = try await request(method: "GET", path: "/api/updates")
        return try decode(UpdatesResponse.self, from: data)
    }

    func getBrightness() async throws -> Int {
        let (data, _) = try await request(method: "GET", path: "/api/brightness")
        return try decode(BrightnessResponse.self, from: data).percent
    }

    func setBrightness(percent: Int) async throws -> Int {
        let body = try encoder.encode(BrightnessRequestBody(percent: percent))
        let (data, _) = try await request(method: "PUT", path: "/api/brightness", jsonBody: body)
        return try decode(BrightnessResponse.self, from: data).percent
    }

    func wake(target: PowerTarget) async throws {
        let body = try encoder.encode(WakeRequestBody(target: target.rawValue))
        _ = try await request(method: "POST", path: "/api/power/wake", jsonBody: body)
    }

    func shutdown(target: PowerTarget, code: String? = nil) async throws {
        let body = try encoder.encode(ShutdownRequestBody(target: target.rawValue, code: code))
        _ = try await request(method: "POST", path: "/api/power/shutdown", jsonBody: body)
    }

    // MARK: - Request plumbing

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private func request(method: String, path: String, jsonBody: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = Constants.requestTimeout

        let token = try HomeserverHTTP.bearerToken(KeychainService.shared.getToken)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let jsonBody {
            urlRequest.httpBody = jsonBody
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await HomeserverHTTP.data(for: urlRequest, session: session)
            let httpResponse = try HomeserverHTTP.successResponse(response, data: data)
            TailscaleConnectivity.shared.recordRequestResult(succeeded: true)
            return (data, httpResponse)
        } catch {
            TailscaleConnectivity.shared.recordRequestResult(succeeded: false)
            throw error
        }
    }
}

private struct BrightnessRequestBody: Encodable {
    let percent: Int
}

private struct ShutdownRequestBody: Encodable {
    let target: String
    let code: String?
}
