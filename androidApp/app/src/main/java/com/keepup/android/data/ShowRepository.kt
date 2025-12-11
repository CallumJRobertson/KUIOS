package com.keepup.android.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.keepup.android.network.*
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private val Context.dataStore by preferencesDataStore("keepup")
private val TRACKED_SHOWS = stringPreferencesKey("tracked_shows")

class ShowRepository(
    private val context: Context,
    private val apiKey: String,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    private val json = Json { ignoreUnknownKeys = true }

    private val service: TmdbService by lazy {
        val logger = HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC }
        val client = OkHttpClient.Builder()
            .addInterceptor(logger)
            .addInterceptor(Interceptor { chain ->
                val request = chain.request().newBuilder()
                    .url(
                        chain.request().url.newBuilder()
                            .addQueryParameter("api_key", apiKey)
                            .build()
                    )
                    .build()
                chain.proceed(request)
            })
            .build()

        Retrofit.Builder()
            .baseUrl("https://api.themoviedb.org/3/")
            .addConverterFactory(MoshiConverterFactory.create())
            .client(client)
            .build()
            .create(TmdbService::class.java)
    }

    val trackedShowsFlow: Flow<List<Show>> = context.dataStore.data.map { prefs ->
        prefs[TRACKED_SHOWS]?.let { json.decodeFromString<List<Show>>(it) } ?: emptyList()
    }

    suspend fun saveTracked(shows: List<Show>) {
        withContext(dispatcher) {
            context.dataStore.edit { prefs ->
                prefs[TRACKED_SHOWS] = json.encodeToString(shows)
            }
        }
    }

    suspend fun search(query: String): List<Show> = withContext(dispatcher) {
        if (query.isBlank()) return@withContext emptyList()
        val response = service.search(query)
        response.results.mapNotNull { result ->
            val type = when (result.mediaType ?: result.title?.let { "movie" } ?: "") {
                "tv" -> ShowType.SERIES
                "movie" -> ShowType.MOVIE
                else -> null
            }

            type?.let {
                val year = (result.releaseDate ?: result.firstAirDate ?: "").take(4)
                Show(
                    id = result.id.toString(),
                    title = result.title ?: result.name ?: "",
                    year = year,
                    type = it,
                    posterUrl = result.posterPath?.let { path -> "https://image.tmdb.org/t/p/w500$path" },
                    backdropUrl = result.backdropPath?.let { path -> "https://image.tmdb.org/t/p/w780$path" }
                )
            }
        }
    }

    suspend fun fetchDetails(show: Show): Show = withContext(dispatcher) {
        when (show.type) {
            ShowType.MOVIE -> service.movie(show.id)
                .toShow(show)
            ShowType.SERIES -> service.tv(show.id)
                .toShow(show)
            else -> show
        }
    }

    suspend fun fetchUpdates(shows: List<Show>): List<Show> = withContext(dispatcher) {
        shows.filter { it.type == ShowType.SERIES }.mapNotNull { tracked ->
            runCatching { service.tv(tracked.id) }.getOrNull()?.let { detail ->
                detail.nextEpisodeToAir?.let { episode ->
                    val airDate = episode.airDate ?: "TBD"
                    val summary = "Next Episode: S${episode.seasonNumber ?: 0}E${episode.episodeNumber ?: 0} on $airDate"
                    tracked.copy(aiSummary = summary)
                }
            }
        }.sortedBy { show ->
            show.nextAirDate?.let {
                runCatching { LocalDate.parse(it, DateTimeFormatter.ISO_DATE) }.getOrNull()
            }
        }
    }

    private fun TmdbMovieDetail.toShow(seed: Show): Show {
        val actors = credits?.cast?.take(5)?.joinToString { it.name }
        val director = credits?.crew?.firstOrNull { it.job == "Director" }?.name
        return seed.copy(
            title = title,
            plot = overview,
            year = releaseDate?.take(4) ?: seed.year,
            runtime = runtime?.let { "$it min" },
            genre = genres?.joinToString { it.name },
            rating = voteAverage?.let { String.format("%.1f", it) },
            actors = actors,
            director = director,
            posterUrl = posterPath?.let { "https://image.tmdb.org/t/p/w500$it" },
            backdropUrl = backdropPath?.let { "https://image.tmdb.org/t/p/w780$it" }
        )
    }

    private fun TmdbTvDetail.toShow(seed: Show): Show {
        val actors = credits?.cast?.take(5)?.joinToString { it.name }
        val creators = createdBy?.joinToString { it.name }
        return seed.copy(
            title = name,
            plot = overview,
            year = firstAirDate?.take(4) ?: seed.year,
            runtime = episodeRunTime?.firstOrNull()?.let { "$it min" },
            genre = genres?.joinToString { it.name },
            rating = voteAverage?.let { String.format("%.1f", it) },
            actors = actors,
            director = creators,
            posterUrl = posterPath?.let { "https://image.tmdb.org/t/p/w500$it" },
            backdropUrl = backdropPath?.let { "https://image.tmdb.org/t/p/w780$it" },
            aiStatus = status,
            aiSummary = nextEpisodeToAir?.let { ep ->
                val air = ep.airDate ?: "TBD"
                "Next Episode: S${ep.seasonNumber ?: 0}E${ep.episodeNumber ?: 0} on $air"
            }
        )
    }
}
