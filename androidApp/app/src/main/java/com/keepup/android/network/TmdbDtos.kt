package com.keepup.android.network

import com.squareup.moshi.Json

data class TmdbSearchResponse(
    val results: List<TmdbSearchResult>,
    @Json(name = "total_results") val totalResults: Int?
)

data class TmdbSearchResult(
    val id: Int,
    val title: String?,
    val name: String?,
    @Json(name = "release_date") val releaseDate: String?,
    @Json(name = "first_air_date") val firstAirDate: String?,
    @Json(name = "media_type") val mediaType: String?,
    @Json(name = "poster_path") val posterPath: String?,
    @Json(name = "backdrop_path") val backdropPath: String?
)

data class TmdbGenre(val id: Int, val name: String)

data class TmdbCredits(
    val cast: List<TmdbCast>?,
    val crew: List<TmdbCrew>?
)

data class TmdbCast(val name: String, val character: String?)
data class TmdbCrew(val name: String, val job: String)

data class TmdbCreator(val name: String)

data class TmdbEpisode(
    @Json(name = "air_date") val airDate: String?,
    @Json(name = "episode_number") val episodeNumber: Int?,
    @Json(name = "season_number") val seasonNumber: Int?
)

data class TmdbMovieDetail(
    val id: Int,
    val title: String,
    val overview: String?,
    @Json(name = "release_date") val releaseDate: String?,
    val runtime: Int?,
    val genres: List<TmdbGenre>?,
    @Json(name = "vote_average") val voteAverage: Double?,
    @Json(name = "poster_path") val posterPath: String?,
    @Json(name = "backdrop_path") val backdropPath: String?,
    val credits: TmdbCredits?
)

data class TmdbTvDetail(
    val id: Int,
    val name: String,
    val overview: String?,
    @Json(name = "first_air_date") val firstAirDate: String?,
    @Json(name = "episode_run_time") val episodeRunTime: List<Int>?,
    val genres: List<TmdbGenre>?,
    @Json(name = "vote_average") val voteAverage: Double?,
    @Json(name = "poster_path") val posterPath: String?,
    @Json(name = "backdrop_path") val backdropPath: String?,
    val credits: TmdbCredits?,
    @Json(name = "created_by") val createdBy: List<TmdbCreator>?,
    val status: String?,
    @Json(name = "next_episode_to_air") val nextEpisodeToAir: TmdbEpisode?
)

data class TmdbVideosResponse(val results: List<TmdbVideo>)
data class TmdbVideo(val key: String, val type: String, val site: String, val official: Boolean?)

data class TmdbWatchProvidersResponse(val results: TmdbWatchProvidersResult?)
data class TmdbWatchProvidersResult(@Json(name = "US") val us: TmdbCountryProviders?)
data class TmdbCountryProviders(val flatrate: List<TmdbProvider>?, val rent: List<TmdbProvider>?, val buy: List<TmdbProvider>?)

data class TmdbProvider(
    @Json(name = "provider_id") val providerId: Int,
    @Json(name = "provider_name") val providerName: String,
    @Json(name = "logo_path") val logoPath: String?
)
