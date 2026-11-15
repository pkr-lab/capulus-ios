import Foundation

final class RemoteWolAgentClient {
    static let shared = RemoteWolAgentClient()

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = Constants.wolAgentBaseURL, session: URLSession = HomeserverHTTP.session) {
        self.baseURL = baseURL
        self.session = session
    }

    func wake(_ target: RemoteWolTarget) async throws {
        let token = try HomeserverHTTP.bearerToken(KeychainService.shared.getWolAgentToken)

        var request = URLRequest(url: baseURL.appendingPathComponent("/wol"))
        request.httpMethod = "POST"
        request.timeoutInterval = Constants.requestTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(WakeRequestBody(target: target.rawValue))

        let (data, response) = try await HomeserverHTTP.data(for: request, session: session)
        _ = try HomeserverHTTP.successResponse(response, data: data)
    }
}
