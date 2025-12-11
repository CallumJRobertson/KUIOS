package com.keepup.android.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class ShowType {
    @SerialName("movie") MOVIE,
    @SerialName("series") SERIES,
    @SerialName("episode") EPISODE,
    @SerialName("other") OTHER;

    val displayName: String
        get() = when (this) {
            MOVIE -> "Movie"
            SERIES -> "TV Show"
            EPISODE -> "Episode"
            OTHER -> "Other"
        }
}

@Serializable
data class WatchProvider(
    val id: Int,
    val name: String,
    @SerialName("logo_path") val logoPath: String? = null
) {
    val logoUrl: String?
        get() = logoPath?.let { "https://image.tmdb.org/t/p/original$it" }
}

@Serializable
data class Source(
    val title: String? = null,
    val url: String? = null
)

@Serializable
data class Show(
    val id: String,
    val title: String,
    val year: String,
    val type: ShowType,
    val posterUrl: String? = null,
    val backdropUrl: String? = null,
    val plot: String? = null,
    val actors: String? = null,
    val director: String? = null,
    val runtime: String? = null,
    val genre: String? = null,
    val rating: String? = null,
    val trailerKey: String? = null,
    val watchProviders: List<WatchProvider>? = null,
    val aiStatus: String? = null,
    val aiSummary: String? = null,
    val aiSources: List<Source>? = null,
    val isCached: Boolean? = null,
    val isNotificationEnabled: Boolean? = null
) {
    val nextAirDate: String?
        get() = aiSummary?.substringAfter("on ")
}
