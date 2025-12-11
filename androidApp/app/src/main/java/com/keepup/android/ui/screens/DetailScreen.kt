package com.keepup.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Button
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.keepup.android.data.Show

@Composable
fun DetailScreen(
    show: Show,
    isTracked: Boolean,
    onToggleTracked: (Show) -> Unit,
    onLoadDetails: () -> Unit,
    onBack: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text(show.title) },
            navigationIcon = {
                IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, contentDescription = null) }
            },
            actions = {
                IconButton(onClick = { onToggleTracked(show) }) {
                    Icon(Icons.Default.Check, contentDescription = null, tint = if (isTracked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface)
                }
            }
        )

        AsyncImage(
            model = show.backdropUrl ?: show.posterUrl,
            contentDescription = null,
            modifier = Modifier
                .fillMaxWidth()
                .height(220.dp)
                .background(MaterialTheme.colorScheme.surfaceVariant)
        )

        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("${show.type.displayName} • ${show.year}", style = MaterialTheme.typography.bodyMedium)
            show.aiStatus?.let { Text(it, style = MaterialTheme.typography.bodyMedium) }
            show.rating?.let { Text("Rating: $it", style = MaterialTheme.typography.bodyMedium) }
            show.runtime?.let { Text("Runtime: $it", style = MaterialTheme.typography.bodyMedium) }
            show.genre?.let { Text("Genre: $it", style = MaterialTheme.typography.bodyMedium) }
            show.actors?.let { Text("Cast: $it", style = MaterialTheme.typography.bodyMedium) }
            show.director?.let { Text("Created by: $it", style = MaterialTheme.typography.bodyMedium) }
            Text(show.plot ?: "No synopsis available yet", style = MaterialTheme.typography.bodyLarge)

            Button(onClick = onLoadDetails, modifier = Modifier.align(Alignment.End)) {
                Text("Load details")
            }
        }
    }
}
