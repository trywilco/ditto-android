package com.ditto.guides.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.ditto.guides.models.AppConfig
import com.ditto.guides.models.Planet
import com.ditto.guides.services.DittoServiceImp
import com.ditto.guides.services.ErrorService
import com.ditto.guides.ui.theme.GuidesTheme
import com.ditto.guides.viewModels.PlanetsListViewModel
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlanetsListView(
    modifier: Modifier = Modifier,
    viewModel: PlanetsListViewModel = koinViewModel()
) {
    val planets by viewModel.planets.collectAsState()
    var showEditor by remember { mutableStateOf(false) }
    var planetToEdit by remember { mutableStateOf<Planet?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Planets") }
            )
        },
        floatingActionButton = {
            Box(
                modifier = Modifier.padding(bottom = 72.dp)
            ) {
                FloatingActionButton(
                    onClick = { 
                        planetToEdit = null
                        showEditor = true
                    },
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.Add, "Add Planet")
                }
            }
        },
        containerColor = MaterialTheme.colorScheme.surfaceVariant
    ) { paddingValues ->
        if (planets.isEmpty()) {
            ContentUnavailable(
                modifier = modifier.padding(paddingValues)
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(
                        top = paddingValues.calculateTopPadding() + 8.dp,
                        bottom = paddingValues.calculateBottomPadding() + 8.dp,
                        start = 16.dp,
                        end = 16.dp
                    ),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(planets) { planet ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        elevation = CardDefaults.cardElevation(
                            defaultElevation = 2.dp
                        )
                    ) {
                        PlanetRow(
                            planet = planet,
                            onEdit = {
                                planetToEdit = planet
                                showEditor = true
                            },
                            onArchive = {
                                viewModel.archivePlanet(planet.planetId)
                            },
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }
        }
        
        if (showEditor) {
            PlanetEditorView(
                planet = planetToEdit,
                onDismiss = { showEditor = false }
            )
        }
    }
}

@Composable
private fun ContentUnavailable(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Public,
            contentDescription = null,
            modifier = Modifier.size(48.dp)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "No Planets",
            style = MaterialTheme.typography.headlineSmall
        )
        Text(
            text = "There are no planets to display",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PlanetRow(
    planet: Planet,
    onEdit: () -> Unit,
    onArchive: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = planet.name,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        
        if (planet.mainAtmosphere.isNotEmpty()) {
            Text(
                text = "Atmosphere: ${planet.mainAtmosphere.joinToString(", ")}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            planet.surfaceTemperatureC.max?.let { max ->
                Text(
                    text = "Max: ${max.toInt()}°C",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
            Text(
                text = "Mean: ${planet.surfaceTemperatureC.mean.toInt()}°C",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.tertiary
            )
            planet.surfaceTemperatureC.min?.let { min ->
                Text(
                    text = "Min: ${min.toInt()}°C",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }

        // Action buttons at the bottom
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilledTonalButton(
                onClick = onEdit,
                modifier = Modifier.padding(end = 8.dp),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Icon(
                    Icons.Default.Edit,
                    contentDescription = "Edit planet",
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.size(8.dp))
                Text("Edit")
            }
            
            FilledTonalButton(
                onClick = onArchive,
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer,
                    contentColor = MaterialTheme.colorScheme.error
                ),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Archive planet",
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.size(8.dp))
                Text("Delete")
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun PlanetListPreview() {
    val context = LocalContext.current
    val errorService: ErrorService = ErrorService()
    val previewDittoService = DittoServiceImp(
        AppConfig(
            "preview_app_id",
            "preview_token",
            "preview.ditto.live"),
        context = context,
        errorService = errorService
    )
    val previewViewModel = PlanetsListViewModel(previewDittoService, errorService)

    GuidesTheme {
        PlanetsListView(viewModel = previewViewModel)
    }
}