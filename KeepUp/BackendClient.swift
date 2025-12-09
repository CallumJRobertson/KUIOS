import Foundation

// 1. Define what the Server sends back
struct BackendResponse: Codable {
    let status: String
    let summary: String
    let sources: [Source]?
    let cached: Bool?
}

// 2. The Messenger
struct BackendClient {
    // 👇 YOUR RENDER URL
    static let baseURL = "https://keepup-backend-5ilq.onrender.com/api/show-status"
    
    // ✅ MODIFIED: Added currentDate parameter
    static func fetchStatus(for showTitle: String, isTV: Bool, currentDate: String) async throws -> BackendResponse {
        guard let url = URL(string: baseURL) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ MODIFIED: Pass date in the body
        let body: [String: Any] = ["showName": showTitle, "isTV": isTV, "currentDate": currentDate]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(BackendResponse.self, from: data)
    }
}
