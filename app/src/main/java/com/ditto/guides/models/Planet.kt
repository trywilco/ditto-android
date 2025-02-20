package com.ditto.guides.models

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class Planet(
    @SerialName("_id") val id: String,
    val hasRings: Boolean,
    val isArchived: Boolean,
    val mainAtmosphere: List<String>,
    val name: String,
    val orderFromSun: Int,
    val planetId: String,
    val surfaceTemperatureC: Temperature) {

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Planet) return false

        return id == other.id &&
                hasRings == other.hasRings &&
                isArchived == other.isArchived &&
                mainAtmosphere == other.mainAtmosphere &&
                name == other.name &&
                orderFromSun == other.orderFromSun &&
                planetId == other.planetId &&
                surfaceTemperatureC == other.surfaceTemperatureC
    }

    override fun hashCode(): Int {
        var result = id.hashCode()

        result += 31 * result + hasRings.hashCode()
        result += 31 * result + isArchived.hashCode()
        result += 31 * result + mainAtmosphere.hashCode()
        result += 31 * result + name.hashCode()
        result += 31 * result + orderFromSun.hashCode()
        result += 31 * result + planetId.hashCode()
        result += 31 * result + surfaceTemperatureC.hashCode()

        return result
    }

    companion object {
        fun fromMap(value: Map<String, Any?>): Planet {
            return Planet(
                id = value["_id"] as String,
                hasRings = value["hasRings"] as Boolean,
                isArchived = value["isArchived"] as Boolean,
                mainAtmosphere = (value["mainAtmosphere"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList(),
                name = value["name"] as String,
                orderFromSun = value["orderFromSun"] as Int,
                planetId = value["planetId"] as String,
                surfaceTemperatureC = (value["surfaceTemperatureC"] as? Map<*, *>)?.let { temp ->
                    Temperature(
                        max = (temp["max"] as? Number)?.toDouble(),
                        mean = (temp["mean"] as? Number)?.toDouble() ?: 0.0,
                        min = (temp["min"] as? Number)?.toDouble()
                    )
                } ?: Temperature(mean = 0.0)
            )
        }
    }

}

@Keep
@Serializable
data class Temperature(
    val max: Double? = null,
    val mean: Double,
    val min: Double? = null) {

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Temperature) return false

        return max == other.max &&
                mean == other.mean &&
                min == other.min
    }

    override fun hashCode(): Int {
        var result = mean.hashCode()
        max?.let {
            result += 31 * result + it.hashCode()
        }
        min?.let {
            result += 31 * result + it.hashCode()
        }
        return result
    }
}