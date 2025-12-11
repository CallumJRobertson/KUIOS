package com.keepup.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Tv
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Modifier
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.keepup.android.ui.AppViewModel
import com.keepup.android.ui.screens.*
import com.keepup.android.ui.theme.KeepUpTheme

data class TabItem(val route: String, val label: String, val icon: @Composable () -> Unit)

class MainActivity : ComponentActivity() {
    private val viewModel: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            KeepUpTheme {
                RootScreen(viewModel)
            }
        }
    }
}

@Composable
private fun RootScreen(viewModel: AppViewModel) {
    val navController = rememberNavController()
    val tabs = listOf(
        TabItem("updates", "Updates") { Icon(Icons.Default.Tv, contentDescription = null) },
        TabItem("search", "Search") { Icon(Icons.Default.Search, contentDescription = null) },
        TabItem("library", "Library") { Icon(Icons.Default.GridView, contentDescription = null) },
        TabItem("settings", "Settings") { Icon(Icons.Default.Settings, contentDescription = null) }
    )

    Scaffold(
        bottomBar = {
            val backStackEntry by navController.currentBackStackEntryAsState()
            val currentRoute = backStackEntry?.destination?.route
            NavigationBar {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute == tab.route,
                        onClick = { navController.navigate(tab.route) { launchSingleTop = true } },
                        label = { Text(tab.label) },
                        icon = tab.icon
                    )
                }
            }
        }
    ) { padding ->
        NavHost(navController = navController, startDestination = "updates", modifier = Modifier.padding(padding)) {
            composable("updates") {
                val updates by viewModel.updates.collectAsState()
                UpdatesScreen(updates = updates, onRefresh = { viewModel.refreshUpdates() }, onSelect = {
                    viewModel.selectShow(it)
                    navController.navigate("detail")
                })
            }
            composable("search") {
                val results by viewModel.searchResults.collectAsState()
                val isLoading by viewModel.isLoading.collectAsState()
                val error by viewModel.lastError.collectAsState()
                SearchScreen(
                    searchText = viewModel.searchText,
                    searchType = viewModel.searchType,
                    results = results,
                    isLoading = isLoading,
                    error = error,
                    onSearchTextChange = { viewModel.searchText = it },
                    onSearchTypeChange = { viewModel.searchType = it },
                    onSearch = { viewModel.performSearch() },
                    onSelect = {
                        viewModel.selectShow(it)
                        navController.navigate("detail")
                    }
                )
            }
            composable("library") {
                val tracked by viewModel.trackedShows.collectAsState()
                LibraryScreen(
                    tracked = tracked,
                    onToggle = { viewModel.toggleTracked(it) },
                    onSelect = {
                        viewModel.selectShow(it)
                        navController.navigate("detail")
                    }
                )
            }
            composable("settings") {
                val tracked by viewModel.trackedShows.collectAsState()
                SettingsScreen(
                    trackedCount = tracked.size,
                    onClearTracked = { tracked.forEach { viewModel.toggleTracked(it) } }
                )
            }
            composable("detail") {
                val selected by viewModel.selectedShow.collectAsState()
                selected?.let { show ->
                    DetailScreen(
                        show = show,
                        isTracked = viewModel.isTracked(show),
                        onToggleTracked = { viewModel.toggleTracked(it) },
                        onLoadDetails = { viewModel.loadDetails(show) { viewModel.selectShow(it) } },
                        onBack = {
                            viewModel.clearSelection()
                            navController.popBackStack()
                        }
                    )
                }
            }
        }
    }
}
