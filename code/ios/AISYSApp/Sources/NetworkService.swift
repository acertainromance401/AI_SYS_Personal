import Foundation

// MARK: - API Response Models

struct SearchAPIResponse: Decodable {
    let total: Int
    let items: [APICase]
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case badStatus(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "서버 오류 (HTTP \(code))"
        case .emptyResponse: return "서버 응답이 비어 있습니다"
        }
    }
}

// MARK: - NetworkService

actor NetworkService {
    static let shared = NetworkService()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        // Info.plist의 API_BASE_URL 키 또는 환경 기본값 사용
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://localhost:8000"
        self.baseURL = URL(string: urlString)!
        self.session = URLSession.shared
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        self.decoder = d
    }

    /// /search?q=...&limit=... → [APICase]
    func searchCases(query: String, limit: Int = 10) async throws -> [APICase] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response)
        return try decoder.decode(SearchAPIResponse.self, from: data).items
    }

    /// /cases/{caseNumber} → APICase
    func getCase(caseNumber: String) async throws -> APICase {
        let url = baseURL
            .appendingPathComponent("cases")
            .appendingPathComponent(caseNumber)
        let (data, response) = try await session.data(from: url)
        try validate(response)
        return try decoder.decode(APICase.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.badStatus(http.statusCode)
        }
    }
}
