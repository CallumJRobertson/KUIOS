// TMDBClient.swift
import Foundation

struct TMDBClient {
    let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    
    // 1. ROBUST SESSION CONFIGURATION
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
    // MARK: - Search
    
    func search(query: String, type: ShowType) async throws -> [Show] {
        let endpoint: String
        switch type {
        case .movie:
            endpoint = "/search/movie"
        case .series:
            endpoint = "/search/tv"
        default:
            endpoint = "/search/multi"
        }

        let request = try buildRequest(endpoint: endpoint, params: [
            "query": query,
            "include_adult": "false"
        ])

        // Debug
        print("🔎 Searching for: \(query)")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 API Response Code: \(httpResponse.statusCode)")
            if !(200...299).contains(httpResponse.statusCode) {
                // Try to decode TMDB-style error payload (status_message)
                if let apiError = try? decoder.decode(TMDBAPIErrorResponse.self, from: data) {
                    throw TMDBError.apiError(apiError.statusMessage)
                }
                let body = String(data: data, encoding: .utf8) ?? "<non-text body>"
                let snippet = body.count > 500 ? String(body.prefix(500)) + "…" : body
                throw TMDBError.apiError("Server returned \(httpResponse.statusCode): \(snippet)")
            }
        }

        // Decode expected search response
        do {
            let searchResponse = try decoder.decode(TMDBSearchResponse.self, from: data)
            print("✅ Found \(searchResponse.results.count) results")
            return searchResponse.results.compactMap { result in
                convertSearchResultToShow(result, requestedType: type)
            }
        } catch {
            // If TMDB returned a structured error object, decode and surface it
            if let apiError = try? decoder.decode(TMDBAPIErrorResponse.self, from: data) {
                throw TMDBError.apiError(apiError.statusMessage)
            }

            // Fallback: some endpoints or proxies may return a raw array of results — try that
            if let rawArray = try? decoder.decode([TMDBSearchResult].self, from: data) {
                print("✅ Fallback: parsed raw results array (\(rawArray.count) entries)")
                return rawArray.compactMap { result in
                    convertSearchResultToShow(result, requestedType: type)
                }
            }

            // Extra fallback: parse JSON and look for a "results" key that may be an array
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let resultsAny = json["results"] {
                if let resultsData = try? JSONSerialization.data(withJSONObject: resultsAny, options: []) {
                    if let parsed = try? decoder.decode([TMDBSearchResult].self, from: resultsData) {
                        print("✅ Fallback: parsed 'results' key with \(parsed.count) entries")
                        return parsed.compactMap { convertSearchResultToShow($0, requestedType: type) }
                    }
                }

                // Manual, lenient mapping fallback: build `Show` from dictionaries
                if let resultsArray = resultsAny as? [[String: Any]] {
                    var manualShows: [Show] = []
                    for item in resultsArray {
                        // extract id (Int or String)
                        let idValue: String
                        if let idInt = item["id"] as? Int {
                            idValue = String(idInt)
                        } else if let idStr = item["id"] as? String {
                            idValue = idStr
                        } else {
                            continue
                        }

                        let title = (item["title"] as? String) ?? (item["name"] as? String) ?? "Untitled"
                        let release = (item["release_date"] as? String) ?? (item["first_air_date"] as? String) ?? ""
                        let posterPath = item["poster_path"] as? String
                        let backdropPath = item["backdrop_path"] as? String
                        let mediaType = item["media_type"] as? String

                        let showType: ShowType
                        if let m = mediaType {
                            showType = m == "movie" ? .movie : .series
                        } else {
                            showType = type
                        }

                        let show = Show(
                            id: idValue,
                            title: title,
                            year: release.isEmpty ? "N/A" : String(release.prefix(4)),
                            type: showType,
                            posterURL: posterURL(path: posterPath),
                            backdropURL: backdropURL(path: backdropPath)
                        )

                        manualShows.append(show)
                    }

                    if !manualShows.isEmpty {
                        print("✅ Manual fallback parsed \(manualShows.count) shows")
                        return manualShows
                    }
                }
            }

            let body = String(data: data, encoding: .utf8) ?? "<non-text body>"
            print("❌ Failed to decode TMDB search response: \(error)\nBody: \(body)")
            // Surface a helpful API error message so the UI can show why parsing failed
            // Map common causes to actionable messages
            let lower = body.lowercased()
            if lower.contains("invalid api key") || lower.contains("api key") && lower.contains("invalid") {
                throw TMDBError.apiError("Invalid TMDB API key. Check Secrets.swift and ensure your API key is valid.")
            }
            if body.contains("<html") || body.contains("<!doctype html") {
                throw TMDBError.apiError("Unexpected HTML response from server (possible proxy or network issue). See logs for body snippet.")
            }

            // Default: short helpful snippet
            let snippet = body.count > 300 ? String(body.prefix(300)) + "…" : body
            throw TMDBError.apiError("Unexpected response from TMDB: \(snippet)")
        }
    }
    
    // MARK: - Fetch Details
    
    func fetchDetails(for id: String, type: ShowType) async throws -> Show {
        let endpoint = type == .movie ? "/movie/\(id)" : "/tv/\(id)"
        
        let request = try buildRequest(endpoint: endpoint, params: [
            "append_to_response": "credits,videos,watch/providers"
        ])
        
        let (data, _) = try await session.data(for: request)
        
        if type == .movie {
            let detail = try decoder.decode(TMDBMovieDetail.self, from: data)
            return convertMovieDetailToShow(detail)
        } else {
            let detail = try decoder.decode(TMDBTVDetail.self, from: data)
            return convertTVDetailToShow(detail)
        }
    }
    
    // MARK: - Fetch Trailer
    
    func fetchTrailer(for id: String, type: ShowType) async throws -> String? {
        let endpoint = type == .movie ? "/movie/\(id)/videos" : "/tv/\(id)/videos"
        
        // ✅ FIX: Use explicit empty dictionary type
        let request = try buildRequest(endpoint: endpoint, params: [String: String]())
        
        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(TMDBVideosResponse.self, from: data)
        
        return response.results.first { video in
            video.site == "YouTube" &&
            video.type == "Trailer" &&
            (video.official ?? false)
        }?.key ?? response.results.first { $0.site == "YouTube" && $0.type == "Trailer" }?.key
    }
    
    // MARK: - Fetch Watch Providers
    
    func fetchWatchProviders(for id: String, type: ShowType) async throws -> [WatchProvider] {
        let endpoint = type == .movie ? "/movie/\(id)/watch/providers" : "/tv/\(id)/watch/providers"
        
        // ✅ FIX: Use explicit empty dictionary type
        let request = try buildRequest(endpoint: endpoint, params: [String: String]())
        
        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(TMDBWatchProvidersResponse.self, from: data)
        
        var providers: [WatchProvider] = []
        
        if let usProviders = response.results?.US {
            if let flatrate = usProviders.flatrate {
                providers.append(contentsOf: flatrate.map { convertProvider($0) })
            }
        }
        
        return providers
    }

    // ✅ ADDED: Function for the 'My Update' Tab
    func fetchNextSeasonDetails(for id: String) async throws -> TMDBTVDetail {
        let endpoint = "/tv/\(id)"
        // ✅ FIX: Use explicit empty dictionary type
        let request = try buildRequest(endpoint: endpoint, params: [String: String]())
        
        let (data, _) = try await session.data(for: request)
        let detail = try decoder.decode(TMDBTVDetail.self, from: data)
        return detail
    }
    
    // MARK: - Helpers
    
    // 3. UPDATED BUILDER TO RETURN URLREQUEST
    private func buildRequest(endpoint: String, params: [String: String]) throws -> URLRequest {
        var components = URLComponents(string: baseURL + endpoint)
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw TMDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // 4. EXPLICIT HEADERS PREVENT -1017 ERRORS
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    private func posterURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "\(imageBaseURL)/w500\(path)")
    }
    
    private func backdropURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "\(imageBaseURL)/original\(path)")
    }
    
    private func convertSearchResultToShow(_ result: TMDBSearchResult, requestedType: ShowType) -> Show? {
        let showTitle = result.title ?? result.name ?? ""
        let year = extractYear(from: result.releaseDate ?? result.firstAirDate ?? "")
        
        var showType: ShowType
        if let mediaType = result.mediaType {
            showType = mediaType == "movie" ? .movie : .series
        } else {
            showType = requestedType
        }
        
        return Show(
            id: String(result.id),
            title: showTitle,
            year: year,
            type: showType,
            posterURL: posterURL(path: result.posterPath),
            backdropURL: backdropURL(path: result.backdropPath)
        )
    }
    
    private func convertMovieDetailToShow(_ detail: TMDBMovieDetail) -> Show {
        let year = extractYear(from: detail.releaseDate ?? "")
        let actors = detail.credits?.cast?.prefix(5).map { $0.name }.joined(separator: ", ")
        let director = detail.credits?.crew?.first { $0.job == "Director" }?.name
        let genres = detail.genres?.map { $0.name }.joined(separator: ", ")
        let runtime = detail.runtime.map { "\($0) min" }
        let rating = detail.voteAverage.map { String(format: "%.1f", $0) }
        
        return Show(
            id: String(detail.id),
            title: detail.title,
            year: year,
            type: .movie,
            posterURL: posterURL(path: detail.posterPath),
            backdropURL: backdropURL(path: detail.backdropPath),
            plot: detail.overview,
            actors: actors,
            director: director,
            runtime: runtime,
            genre: genres,
            rating: rating
        )
    }
    
    private func convertTVDetailToShow(_ detail: TMDBTVDetail) -> Show {
        let year = extractYear(from: detail.firstAirDate ?? "")
        let actors = detail.credits?.cast?.prefix(5).map { $0.name }.joined(separator: ", ")
        let creator = detail.createdBy?.first?.name
        let genres = detail.genres?.map { $0.name }.joined(separator: ", ")
        let runtime = detail.episodeRunTime?.first.map { "\($0) min" }
        let rating = detail.voteAverage.map { String(format: "%.1f", $0) }
        
        return Show(
            id: String(detail.id),
            title: detail.name,
            year: year,
            type: .series,
            posterURL: posterURL(path: detail.posterPath),
            backdropURL: backdropURL(path: detail.backdropPath),
            plot: detail.overview,
            actors: actors,
            director: creator,
            runtime: runtime,
            genre: genres,
            rating: rating
        )
    }
    
    private func convertProvider(_ provider: TMDBProvider) -> WatchProvider {
        WatchProvider(
            id: provider.providerId,
            name: provider.providerName,
            logoPath: provider.logoPath
        )
    }
    
    private func extractYear(from dateString: String) -> String {
        if dateString.isEmpty { return "N/A" }
        return String(dateString.prefix(4))
    }
}

// Small helper to parse TMDB error responses
private struct TMDBAPIErrorResponse: Decodable {
    let statusMessage: String
    let statusCode: Int?
    enum CodingKeys: String, CodingKey {
        case statusMessage = "status_message"
        case statusCode = "status_code"
    }
}
