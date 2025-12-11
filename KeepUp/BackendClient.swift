import Foundation

struct BackendResponse: Codable {
    let status: String
    let summary: String
    let sources: [Source]?
    let cached: Bool?
}

struct BackendClient {
    // 👇 YOUR RENDER URL
    static let baseURL = "https://keepup-backend-5ilq.onrender.com"
    
    // MARK: - Existing Status Check
    static func fetchStatus(for showTitle: String, isTV: Bool, currentDate: String) async throws -> BackendResponse {
        guard let url = URL(string: "\(baseURL)/api/show-status") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["showName": showTitle, "isTV": isTV, "currentDate": currentDate]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(BackendResponse.self, from: data)
    }
    
    // MARK: - Smart Briefing
    struct BriefingRequest: Codable {
        let updates: [ShowStub]
        let userDate: String
    }
    
    struct ShowStub: Codable {
        let title: String
        let nextAirDate: String?
    }
    
    struct BriefingResponse: Codable {
        let briefing: String
        let cached: Bool? // ✅ NEW: Check if backend served from cache
    }

    // ✅ CHANGED: Returns BriefingResponse instead of String
    static func fetchBriefing(for shows: [Show]) async throws -> BriefingResponse? {
        guard let url = URL(string: "\(baseURL)/api/generate-briefing") else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayStr = dateFormatter.string(from: Date())
        
        let stubs = shows.compactMap { show -> ShowStub? in
            guard let date = show.nextAirDate else { return nil }
            return ShowStub(
                title: show.title,
                nextAirDate: dateFormatter.string(from: date)
            )
        }
        
        if stubs.isEmpty { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(BriefingRequest(updates: stubs, userDate: todayStr))
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(BriefingResponse.self, from: data)
    }
}