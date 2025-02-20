package com.ditto.guides.services

import android.content.Context
import com.ditto.guides.models.AppConfig
import com.ditto.guides.models.Planet
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import live.ditto.Ditto
import live.ditto.DittoError
import live.ditto.DittoIdentity
import live.ditto.DittoLogLevel
import live.ditto.DittoLogger
import live.ditto.DittoStoreObserver
import live.ditto.DittoSyncSubscription
import live.ditto.android.DefaultAndroidDittoDependencies

interface DittoService {
    val ditto: Ditto?
    fun getPlanets(): Flow<List<Planet>>

    /**
     * Updates an existing planet in the Ditto store.
     *
     * This method:
     * - Updates all mutable fields of the planet
     * - Maintains the planet's ID and references
     * - Triggers a sync with other devices
     *
     * @param planet The updated Planet object containing all changes
     * @throws Exception if the update operation fails
     */
    suspend fun updatePlanet(planet: Planet)

    /**
     * Adds a new planet to the Ditto store.
     *
     * This method:
     * - Creates a new document in the planets collection
     * - Assigns the provided ID and properties
     * - Triggers a sync with other devices
     *
     * The planet object should have:
     * - A unique ID
     * - All required fields populated
     * - isArchived set to false
     *
     * @param planet The new Planet object to be added
     * @throws Exception if the insert operation fails
     */
    suspend fun addPlanet(planet: Planet)

    /**
     * Archives a planet by setting its isArchived flag to true.
     *
     * This method:
     * - Marks the planet as archived instead of deleting it
     * - Removes it from active queries and views
     * - Maintains the data for historical purposes
     * - Triggers a sync with other devices
     *
     * Archived planets:
     * - Are excluded from the main planet list
     * - Can be restored if needed
     * - Maintain their original properties
     *
     * @param planetId The unique identifier of the planet to archive
     * @throws Exception if the archive operation fails
     */
    suspend fun archivePlanet(planetId: String)
}

class DittoServiceImp(
    appConfig: AppConfig,
    context: Context,
    private val errorService: ErrorService
) : DittoService {

    override var ditto: Ditto? = null
    private var subscription: DittoSyncSubscription? = null
    private var planetObserver: DittoStoreObserver? = null

    init {
        try {
            DittoLogger.minimumLogLevel = DittoLogLevel.DEBUG
            val androidDependencies = DefaultAndroidDittoDependencies(context)

            //
            // CustomUrl is used because Connector is in Private Preview
            // and uses a different cluster than normal production
            //
            val customAuthUrl = "https://${appConfig.endpointUrl}"
            val webSocketUrl = "wss://${appConfig.endpointUrl}"

            //
            // TODO remove when Connector is out of Private Preview
            // https://docs.ditto.live/sdk/latest/install-guides/kotlin#integrating-and-initializing
            val identity = DittoIdentity.OnlinePlayground(
                androidDependencies,
                appConfig.appId,
                appConfig.authToken,
                false,
                customAuthUrl
            )
            this.ditto = Ditto(androidDependencies, identity)
            ditto?.updateTransportConfig { config ->
                config.connect.websocketUrls.add(webSocketUrl)
            }

            setupSubscriptions()

        } catch (e: DittoError) {
            errorService.showError("Failed to initialize Ditto: ${e.message}")
        }
    }

    /**
     * Sets up the initial subscription to the planets collection in Ditto.
     * This subscription ensures that changes to the planets collection are synced
     * between the local Ditto store and the MongoDB Atlas database.
     * https://docs.ditto.live/sdk/latest/sync/syncing-data#creating-subscriptions
     *
     * The subscription:
     * - Queries all non-archived planets (isArchived = false)
     * - Starts the sync process with the Ditto cloud
     * - Maintains the subscription until the app is terminated or sync is stopped
     *
     * Note: This is different from the observer which notifies of data changes.
     * This subscription is responsible for the actual data synchronization.
     */
    private fun setupSubscriptions() {
        try {
            this.ditto?.let {
                this.subscription = it.sync.registerSubscription(
                    """
                    SELECT *
                    FROM planets
                    WHERE isArchived = :isArchived
                    """, mapOf("isArchived" to false)
                )
                it.startSync()
            }
        } catch (e: Exception) {
            errorService.showError("Failed to setup ditto subscription: ${e.message}")
        }
    }

    /**
     * Creates a Flow that observes and emits changes to the planets collection in Ditto.
     * https://docs.ditto.live/sdk/latest/crud/read#using-args-to-query-dynamic-values
     *
     * This method:
     * - Sets up a live query observer for the planets collection
     * - Emits a new list of planets whenever the data changes
     * - Automatically cleans up the observer when the flow is cancelled
     *
     * The query:
     * - Returns all non-archived planets (isArchived = false)
     * - Orders the results by distance from the sun
     * - Transforms raw Ditto data into Planet objects
     *
     * @return Flow<List<Planet>> A flow that emits updated lists of planets
     * whenever changes occur in the collection
     */
    override fun getPlanets(): Flow<List<Planet>> = callbackFlow {
        // Return empty flow for now
        trySend(emptyList())
        awaitClose { }
    }

    /**
     * Updates an existing planet's properties in the Ditto store.
     * https://docs.ditto.live/sdk/latest/crud/update#updating 
     * Implementation details:
     * - Uses DQL to update the document
     *
     * @param planet The Planet object containing updated values
     */
    override suspend fun updatePlanet(planet: Planet) {
        // Empty implementation - will be implemented later
    }

    /**
     * Creates a new planet document in the Ditto store.
     * https://docs.ditto.live/sdk/latest/crud/create#creating-documents
     * 
     * Implementation details:
     * - Inserts a complete document with all required fields using DQL
     *
     * @param planet The new Planet object to insert
     */
    override suspend fun addPlanet(planet: Planet) {
        // Empty implementation - will be implemented later
    }

    /**
     * Marks a planet as archived in the Ditto store.  
     * This uses the 'Soft-Delete' pattern:  https://docs.ditto.live/sdk/latest/crud/delete#soft-delete-pattern  
     * 
     * Implementation details:
     * - Uses a simple DQL UPDATE query to set isArchived flag
     *
     * @param planetId The unique identifier of the planet to archive
     */
    override suspend fun archivePlanet(planetId: String) {
        // Empty implementation - will be implemented later
    }
}