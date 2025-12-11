package com.keepup.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.keepup.android.data.Show
import com.keepup.android.data.ShowType
import com.keepup.android.ui.components.ShowCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    searchText: String,
    searchType: ShowType,
    results: List<Show>,
    isLoading: Boolean,
    error: String?,
    onSearchTextChange: (String) -> Unit,
    onSearchTypeChange: (ShowType) -> Unit,
    onSearch: () -> Unit,
    onSelect: (Show) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        OutlinedTextField(
            value = searchText,
            onValueChange = onSearchTextChange,
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Search movies & shows") },
            singleLine = true,
            keyboardOptions = androidx.compose.ui.text.input.KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = androidx.compose.ui.text.input.KeyboardActions(onSearch = { onSearch() })
        )

        Spacer(Modifier.height(8.dp))
        FilterChipRow(selected = searchType, onSelect = onSearchTypeChange)

        Spacer(Modifier.height(12.dp))
        Button(onClick = onSearch, enabled = !isLoading) { Text("Search") }

        if (isLoading) {
            LinearProgressIndicator(modifier = Modifier.fillMaxWidth().padding(top = 8.dp))
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(vertical = 8.dp)) }

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(results) { show ->
                ShowCard(show = show, modifier = Modifier.padding(vertical = 6.dp)) { onSelect(show) }
            }
        }
    }
}

@Composable
private fun FilterChipRow(selected: ShowType, onSelect: (ShowType) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        ShowType.values().filter { it == ShowType.MOVIE || it == ShowType.SERIES }.forEach { type ->
            FilterChip(
                selected = selected == type,
                onClick = { onSelect(type) },
                label = { Text(type.displayName) }
            )
        }
    }
}
