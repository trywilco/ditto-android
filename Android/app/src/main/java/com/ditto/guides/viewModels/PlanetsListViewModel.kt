package com.ditto.guides.viewModels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ditto.guides.models.Planet
import com.ditto.guides.services.DittoService
import com.ditto.guides.services.ErrorService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class PlanetsListViewModel(
    private val dittoService: DittoService,
    private val errorService: ErrorService
) : ViewModel() {

    private val _planets = MutableStateFlow<List<Planet>>(emptyList())
    val planets: StateFlow<List<Planet>> = _planets.asStateFlow()

    init {
        viewModelScope.launch {
            dittoService.getPlanets()
                .collect { planetsList ->
                    _planets.value = planetsList
                }
        }
    }

    fun archivePlanet(planetId: String) {
        viewModelScope.launch {
            try {
                dittoService.archivePlanet(planetId)
            } catch (e: Exception) {
                errorService.showError("Failed to archive planet: ${e.message}")
            }
        }
    }
} 