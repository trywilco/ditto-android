package com.ditto.guides.viewModels

import androidx.lifecycle.ViewModel
import com.ditto.guides.models.Planet
import com.ditto.guides.services.DittoService

class PlanetEditorViewModel(
    private val dittoService: DittoService,
    val selected: Planet?) : ViewModel() {

}