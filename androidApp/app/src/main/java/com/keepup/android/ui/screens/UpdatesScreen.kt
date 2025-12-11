package com.keepup.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.keepup.android.data.Show
import com.keepup.android.ui.components.ShowCard

@Composable
fun UpdatesScreen(
    updates: List<Show>,
    onRefresh: () -> Unit,
    onSelect: (Show) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Button(onClick = onRefresh) { Text("Refresh Updates") }
        Spacer(Modifier.height(12.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(updates) { show ->
                ShowCard(show = show) { onSelect(show) }
            }
        }
    }
}
