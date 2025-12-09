// TMDBClient.swift
import Foundation

struct TMDBClient {
    let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    
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
        
        guard let url = buildURL(endpoint: endpoint, params: [
            "query": query,
            "include_adult": "false"
        ]) else {
            throw TMDBError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TMDBSearchResponse.self, from: data)
        
        return response.results.compactMap { result in
            convertSearchResultToShow(result, requestedType: type)
        }
    }
    
    // MARK: - Fetch Details
    
    func fetchDetails(for id: String, type: ShowType) async throws -> Show {
        let endpoint = type == .movie ? "/movie/\(id)" : "/tv/\(id)"
        
        guard let url = buildURL(endpoint: endpoint, params: [
            "append_to_response": "credits,videos,watch/providers"
        ]) else {
            throw TMDBError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
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
        
        guard let url = buildURL(endpoint: endpoint, params: [:]) else {
            throw TMDBError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TMDBVideosResponse.self, from: data)
        
        // Find official trailer on YouTube
        return response.results.first { video in
            video.site == "YouTube" &&
            video.type == "Trailer" &&
            (video.official ?? false)
        }?.key ?? response.results.first { $0.site == "YouTube" && $0.type == "Trailer" }?.key
    }
    
    // MARK: - Fetch Watch Providers
    
    func fetchWatchProviders(for id: String, type: ShowType) async throws -> [WatchProvider] {
        let endpoint = type == .movie ? "/movie/\(id)/watch/providers" : "/tv/\(id)/watch/providers"
        
        guard let url = buildURL(endpoint: endpoint, params: [:]) else {
            throw TMDBError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TMDBWatchProvidersResponse.self, from: data)
        
        var providers: [WatchProvider] = []
        
        if let usProviders = response.results?.US {
            if let flatrate = usProviders.flatrate {
                providers.append(contentsOf: flatrate.map { convertProvider($0) })
            }
        }
        
        return providers
    }
    
    // MARK: - Helpers
    
    private func buildURL(endpoint: String, params: [String: String]) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        components?.queryItems = queryItems
        return components?.url
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
