package com.keepup.android.network

import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface TmdbService {
    @GET("search/multi")
    suspend fun search(@Query("query") query: String): TmdbSearchResponse

    @GET("movie/{id}")
    suspend fun movie(@Path("id") id: String, @Query("append_to_response") append: String = "credits,videos"):
        TmdbMovieDetail

    @GET("tv/{id}")
    suspend fun tv(@Path("id") id: String, @Query("append_to_response") append: String = "credits,videos"):
        TmdbTvDetail

    @GET("movie/{id}/watch/providers")
    suspend fun movieProviders(@Path("id") id: String): TmdbWatchProvidersResponse

    @GET("tv/{id}/watch/providers")
    suspend fun tvProviders(@Path("id") id: String): TmdbWatchProvidersResponse
}
