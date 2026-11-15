import Foundation

enum HomeserverHTTP {
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.requestTimeout
        config.waitsForConnectivity = false
        return URLSession(configuration: config, delegate: MTLSDelegate(), delegateQueue: nil)
    }()

    static let publicSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.requestTimeout
        return URLSession(configuration: config)
    }()

    static func data(for request: URLRequest, session: URLSession = HomeserverHTTP.session) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    static func successResponse(_ response: URLResponse, data: Data) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.error
            throw APIError.badResponse(statusCode: status, message: message)
        }
        return httpResponse
    }

    static func bearerToken(_ read: () throws -> String) throws -> String {
        do {
            return try read()
        } catch KeychainError.notFound {
            throw APIError.missingToken
        }
    }
}

struct APIErrorBody: Decodable {
    let error: String
}

struct WakeRequestBody: Encodable {
    let target: String
}
