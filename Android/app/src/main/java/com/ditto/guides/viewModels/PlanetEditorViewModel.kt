package com.ditto.guides.viewModels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ditto.guides.models.Planet
import com.ditto.guides.models.Temperature
import com.ditto.guides.services.DittoService
import com.ditto.guides.services.ErrorService
import kotlinx.coroutines.launch
import java.util.UUID

class PlanetEditorViewModel (
    private val dittoService: DittoService,
    private val errorService: ErrorService
) : ViewModel() {
    var name by mutableStateOf("")
    var orderFromSun by mutableIntStateOf(1)
    var hasRings by mutableStateOf(false)
    var atmosphere by mutableStateOf("")
    var maxTemp by mutableStateOf<Double?>(null)
    var meanTemp by mutableDoubleStateOf(0.0)
    var minTemp by mutableStateOf<Double?>(null)
    private var existingPlanet: Planet? = null

    fun initializeWithPlanet(planet: Planet?) {
        existingPlanet = planet
        planet?.let {
            name = it.name
            orderFromSun = it.orderFromSun
            hasRings = it.hasRings
            atmosphere = it.mainAtmosphere.joinToString(", ")
            maxTemp = it.surfaceTemperatureC.max
            meanTemp = it.surfaceTemperatureC.mean
            minTemp = it.surfaceTemperatureC.min
        } ?: resetFields()
    }

    private fun resetFields() {
        name = ""
        orderFromSun = 1
        hasRings = false
        atmosphere = ""
        maxTemp = null
        meanTemp = 0.0
        minTemp = null
    }

    fun savePlanet() {
        viewModelScope.launch {
            try {
                val atmosphereList = atmosphere
                    .split(",")
                    .map { it.trim() }
                    .filter { it.isNotEmpty() }

                if (existingPlanet != null) {
                    // Update existing planet
                    val updatedPlanet = Planet(
                        id = existingPlanet!!.id,
                        hasRings = hasRings,
                        isArchived = false,
                        mainAtmosphere = atmosphereList,
                        name = name,
                        orderFromSun = orderFromSun,
                        planetId = existingPlanet!!.planetId,
                        surfaceTemperatureC = Temperature(
                            max = maxTemp,
                            mean = meanTemp,
                            min = minTemp
                        )
                    )
                    dittoService.updatePlanet(updatedPlanet)
                } else {
                    // Create new planet
                    val id = UUID.randomUUID().toString()
                    val newPlanet = Planet(
                        id = id,
                        hasRings = hasRings,
                        isArchived = false,
                        mainAtmosphere = atmosphereList,
                        name = name,
                        orderFromSun = orderFromSun,
                        planetId = id,
                        surfaceTemperatureC = Temperature(
                            max = maxTemp,
                            mean = meanTemp,
                            min = minTemp
                        )
                    )
                    dittoService.addPlanet(newPlanet)
                }
            } catch (e: Exception) {
                errorService.showError("Failed to save planet: ${e.message}")
            }
        }
    }
}