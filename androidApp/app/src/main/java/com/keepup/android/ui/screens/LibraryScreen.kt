package com.keepup.android.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.keepup.android.data.Show
import com.keepup.android.data.ShowType
import com.keepup.android.ui.components.ShowCard

@Composable
fun LibraryScreen(
    tracked: List<Show>,
    onToggle: (Show) -> Unit,
    onSelect: (Show) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        Text("Series", modifier = Modifier.padding(16.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(tracked.filter { it.type == ShowType.SERIES }) { show ->
                ShowCard(show = show, modifier = Modifier.padding(horizontal = 16.dp)) {
                    onSelect(show)
                }
            }
        }
        Spacer(Modifier.height(16.dp))
        Text("Movies", modifier = Modifier.padding(16.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(tracked.filter { it.type == ShowType.MOVIE }) { show ->
                ShowCard(show = show, modifier = Modifier.padding(horizontal = 16.dp), trailing = {
                    IconButton(onClick = { onToggle(show) }) { Icon(Icons.Default.Check, contentDescription = null) }
                }) {
                    onSelect(show)
                }
            }
        }
    }
}
