// Models.swift
import Foundation

// MARK: - Show type (movie / series / etc.)

enum ShowType: String, Codable, CaseIterable, Identifiable {
    case movie
    case series
    case episode
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .movie:   return "Movie"
        case .series:  return "TV Show"
        case .episode: return "Episode"
        case .other:   return "Other"
        }
    }
}

// MARK: - Core app model

struct Show: Identifiable, Codable, Equatable {
    let id: String        // TMDB ID as string
    let title: String
    let year: String
    let type: ShowType
    let posterURL: URL?
    let backdropURL: URL?  // NEW: For hero images
    
    // Detail info
    var plot: String?
    var actors: String?
    var director: String?
    var runtime: String?
    var genre: String?
    var rating: String?
    var trailerKey: String?  // NEW: YouTube key for trailer
    
    // NEW: Streaming availability
    var watchProviders: [WatchProvider]?
    
    // NEW: Cached AI status
    var aiStatus: String?
    var aiSummary: String?
    var aiSources: [Source]?
    
    var hasDetails: Bool {
        plot != nil || actors != nil || director != nil || genre != nil || rating != nil
    }
}

// MARK: - Watch Provider

struct WatchProvider: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let logoPath: String?
    
    var logoURL: URL? {
        guard let path = logoPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(path)")
    }
}

// MARK: - TMDB DTOs

struct TMDBSearchResponse: Decodable {
    let results: [TMDBSearchResult]
    let totalResults: Int?
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalResults = "total_results"
    }
}

struct TMDBSearchResult: Decodable, Identifiable {
    let id: Int
    let title: String?
    let name: String?  // TV shows use 'name' instead of 'title'
    let releaseDate: String?
    let firstAirDate: String?
    let mediaType: String?
    let posterPath: String?
    let backdropPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, name
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case mediaType = "media_type"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

struct TMDBMovieDetail: Decodable {
    let id: Int
    let title: String
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let genres: [TMDBGenre]?
    let voteAverage: Double?
    let posterPath: String?
    let backdropPath: String?
    let credits: TMDBCredits?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, credits
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

struct TMDBTVDetail: Decodable {
    let id: Int
    let name: String
    let overview: String?
    let firstAirDate: String?
    let episodeRunTime: [Int]?
    let genres: [TMDBGenre]?
    let voteAverage: Double?
    let posterPath: String?
    let backdropPath: String?
    let credits: TMDBCredits?
    let createdBy: [TMDBCreator]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, credits
        case firstAirDate = "first_air_date"
        case episodeRunTime = "episode_run_time"
        case voteAverage = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case createdBy = "created_by"
    }
}

struct TMDBGenre: Decodable {
    let id: Int
    let name: String
}

struct TMDBCredits: Decodable {
    let cast: [TMDBCast]?
    let crew: [TMDBCrew]?
}

struct TMDBCast: Decodable {
    let name: String
    let character: String?
}

struct TMDBCrew: Decodable {
    let name: String
    let job: String
}

struct TMDBCreator: Decodable {
    let name: String
}

struct TMDBVideosResponse: Decodable {
    let results: [TMDBVideo]
}

struct TMDBVideo: Decodable {
    let key: String
    let type: String
    let site: String
    let official: Bool?
}

struct TMDBWatchProvidersResponse: Decodable {
    let results: TMDBWatchProvidersResult?
}

struct TMDBWatchProvidersResult: Decodable {
    let US: TMDBCountryProviders?
    
    enum CodingKeys: String, CodingKey {
        case US = "US"
    }
}

struct TMDBCountryProviders: Decodable {
    let flatrate: [TMDBProvider]?
    let rent: [TMDBProvider]?
    let buy: [TMDBProvider]?
}

struct TMDBProvider: Decodable {
    let providerId: Int
    let providerName: String
    let logoPath: String?
    
    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
    }
}

// MARK: - Backend Source (unchanged)

struct Source: Codable, Equatable {
    let title: String?
    let url: String?
}

// MARK: - Errors

enum TMDBError: Error, LocalizedError {
    case invalidURL
    case apiError(String)
    case decodingError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build a valid request."
        case .apiError(let message):
            return message
        case .decodingError:
            return "Could not read the response from the server."
        case .unknown:
            return "Something went wrong."
        }
    }
}
