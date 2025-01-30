package com.ditto.guides.models

import androidx.annotation.Keep

@Keep
data class AppConfig(
	val endpointUrl: String, 
	val appId: String, 
	val authToken: String)