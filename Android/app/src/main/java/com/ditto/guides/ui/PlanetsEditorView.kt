package com.ditto.guides.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.ditto.guides.models.Planet
import com.ditto.guides.viewModels.PlanetEditorViewModel
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlanetEditorView(
    modifier: Modifier = Modifier,
    planet: Planet? = null,
    onDismiss: () -> Unit,
    viewModel: PlanetEditorViewModel = koinViewModel()
) {
    LaunchedEffect(planet) {
        viewModel.initializeWithPlanet(planet)
    }

    val sheetState = rememberModalBottomSheetState(
        skipPartiallyExpanded = true // Force full expansion
    )
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        scope.launch {
            sheetState.expand()
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        modifier = modifier
            .fillMaxHeight()
            .fillMaxWidth(),
        dragHandle = null,
        sheetState = sheetState,
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(if (planet == null) "Add Planet" else "Edit Planet") },
                    navigationIcon = {
                        IconButton(onClick = onDismiss) {
                            Icon(Icons.Default.Close, "Close")
                        }
                    },
                    actions = {
                        TextButton(
                            onClick = {
                                viewModel.savePlanet()
                                onDismiss()
                            },
                            enabled = viewModel.name.isNotEmpty()
                        ) {
                            Text("Save")
                        }
                    }
                )
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Card {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            "Basic Information",
                            style = MaterialTheme.typography.titleMedium
                        )
                        
                        OutlinedTextField(
                            value = viewModel.name,
                            onValueChange = { viewModel.name = it },
                            label = { Text("Name") },
                            modifier = Modifier.fillMaxWidth()
                        )
                        
                        OutlinedTextField(
                            value = viewModel.orderFromSun.toString(),
                            onValueChange = { 
                                viewModel.orderFromSun = it.toIntOrNull() ?: 1
                            },
                            label = { Text("Order from Sun") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth()
                        )
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Has Rings")
                            Switch(
                                checked = viewModel.hasRings,
                                onCheckedChange = { viewModel.hasRings = it }
                            )
                        }
                    }
                }

                Card {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            "Atmosphere",
                            style = MaterialTheme.typography.titleMedium
                        )
                        
                        OutlinedTextField(
                            value = viewModel.atmosphere,
                            onValueChange = { viewModel.atmosphere = it },
                            label = { Text("Enter atmospheres (comma separated)") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }

                Card {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            "Surface Temperature (°C)",
                            style = MaterialTheme.typography.titleMedium
                        )
                        
                        OutlinedTextField(
                            value = viewModel.maxTemp?.toString() ?: "",
                            onValueChange = { 
                                viewModel.maxTemp = it.toDoubleOrNull()
                            },
                            label = { Text("Maximum") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth()
                        )
                        
                        OutlinedTextField(
                            value = viewModel.meanTemp.toString(),
                            onValueChange = { 
                                viewModel.meanTemp = it.toDoubleOrNull() ?: 0.0
                            },
                            label = { Text("Mean") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth()
                        )
                        
                        OutlinedTextField(
                            value = viewModel.minTemp?.toString() ?: "",
                            onValueChange = { 
                                viewModel.minTemp = it.toDoubleOrNull()
                            },
                            label = { Text("Minimum") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }
    }
}