package com.ditto.guides.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.ditto.guides.models.AppConfig
import com.ditto.guides.models.Planet
import com.ditto.guides.services.DittoServiceImp
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Planets") }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { viewModel.addPlanet() },
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                contentColor = MaterialTheme.colorScheme.onPrimaryContainer
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add Planet"
                )
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
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }
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
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = planet.name,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
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
                    color = MaterialTheme.colorScheme.error  // Red for maximum temperature
                )
            }
            Text(
                text = "Mean: ${planet.surfaceTemperatureC.mean.toInt()}°C",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.tertiary  // Orange for mean temperature
            )
            planet.surfaceTemperatureC.min?.let { min ->
                Text(
                    text = "Min: ${min.toInt()}°C",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary  // Blue for minimum temperature
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun PlanetListPreview() {
    val context = LocalContext.current
    val previewDittoService = DittoServiceImp(
        AppConfig(
            "preview_app_id",
            "preview_token",
            "preview.ditto.live"),
        context = context
    )
    val previewViewModel = PlanetsListViewModel(previewDittoService)

    GuidesTheme {
        PlanetsListView(viewModel = previewViewModel)
    }
}