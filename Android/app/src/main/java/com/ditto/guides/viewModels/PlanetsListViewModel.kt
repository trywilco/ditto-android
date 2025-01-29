package com.ditto.guides.viewModels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ditto.guides.models.Planet
import com.ditto.guides.services.DittoService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class PlanetsListViewModel(
    private val dittoService: DittoService
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
    
    fun addPlanet() {
        // TODO: Implement planet addition logic
        Log.d("PlanetsListViewModel", "Add planet clicked")
    }
} 