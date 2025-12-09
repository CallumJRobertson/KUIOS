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
        
        // 2. USE URLREQUEST WITH HEADERS
        let request = try buildRequest(endpoint: endpoint, params: [
            "query": query,
            "include_adult": "false"
        ])
        
        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(TMDBSearchResponse.self, from: data)
        
        return response.results.compactMap { result in
            convertSearchResultToShow(result, requestedType: type)
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
