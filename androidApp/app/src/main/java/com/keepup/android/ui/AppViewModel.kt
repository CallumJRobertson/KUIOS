package com.keepup.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.keepup.android.BuildConfig
import com.keepup.android.data.Show
import com.keepup.android.data.ShowRepository
import com.keepup.android.data.ShowType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class AppViewModel(app: Application) : AndroidViewModel(app) {
    private val repository = ShowRepository(app, apiKey = "${'$'}{BuildConfig.TMDB_API_KEY ?: ""}")

    val trackedShows: StateFlow<List<Show>> = repository.trackedShowsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _searchResults = MutableStateFlow<List<Show>>(emptyList())
    val searchResults: StateFlow<List<Show>> = _searchResults

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _lastError = MutableStateFlow<String?>(null)
    val lastError: StateFlow<String?> = _lastError

    private val _updates = MutableStateFlow<List<Show>>(emptyList())
    val updates: StateFlow<List<Show>> = _updates

    private val _selectedShow = MutableStateFlow<Show?>(null)
    val selectedShow: StateFlow<Show?> = _selectedShow

    var searchType: ShowType = ShowType.SERIES
    var searchText: String = ""

    fun performSearch() {
        val query = searchText.trim()
        if (query.isEmpty()) {
            _searchResults.value = emptyList()
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            _lastError.value = null
            runCatching { repository.search(query) }
                .onSuccess { _searchResults.value = it }
                .onFailure { _lastError.value = it.message }
            _isLoading.value = false
        }
    }

    fun toggleTracked(show: Show) {
        viewModelScope.launch {
            val newList = trackedShows.value.toMutableList().apply {
                if (any { it.id == show.id }) removeAll { it.id == show.id } else add(show)
            }
            repository.saveTracked(newList)
        }
    }

    fun isTracked(show: Show) = trackedShows.value.any { it.id == show.id }

    fun selectShow(show: Show) {
        _selectedShow.value = show
    }

    fun clearSelection() {
        _selectedShow.value = null
    }

    fun refreshUpdates() {
        viewModelScope.launch {
            _updates.value = repository.fetchUpdates(trackedShows.value)
        }
    }

    fun loadDetails(show: Show, onLoaded: (Show) -> Unit) {
        viewModelScope.launch {
            val details = runCatching { repository.fetchDetails(show) }.getOrNull()
            details?.let(onLoaded)
        }
    }
}
