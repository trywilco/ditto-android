package com.ditto.guides.services

import android.content.Context
import android.util.Log
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

interface DittoService{
    fun getPlanets(): Flow<List<Planet>>
}

class DittoServiceImp (
    private val appConfig: AppConfig,
    private val context: Context): DittoService {

    private var ditto:Ditto? = null
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
            //
            val identity = DittoIdentity.OnlinePlayground(
                androidDependencies,
                appConfig.appId,
                appConfig.authToken,
                false,
                customAuthUrl)
            this.ditto = Ditto(androidDependencies, identity)
            ditto?.updateTransportConfig { config ->
                config.connect.websocketUrls.add(webSocketUrl)
            }

            setupSubscriptions()

        } catch(e: DittoError){
         Log.e("Ditto error", e.message!!)
        }
    }

    /**
     * Sets up the initial subscription to the planets collection in Ditto.
     * This subscription ensures that changes to the planets collection are synced
     * between the local Ditto store and the MongoDB Atlas database.
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
        this.ditto?.let {
            this.subscription = it.sync.registerSubscription(
                """
                    SELECT *
                    FROM planets
                    WHERE isArchived = :isArchived
                    """, mapOf("isArchived" to false))
            it.startSync()
        }
    }

    /**
     * Creates a Flow that observes and emits changes to the planets collection in Ditto.
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
     *
     */
    override fun getPlanets(): Flow<List<Planet>> = callbackFlow {
        ditto?.let { ditto ->
            planetObserver = ditto.store.registerObserver("""
                SELECT *
                FROM planets
                WHERE isArchived = :isArchived
                ORDER BY orderFromSun
            """, mapOf("isArchived" to false)) { results ->
                val planets = results.items.map { item ->
                    Planet.fromMap(item.value)
                }
                trySend(planets)
            }
        }

        // Clean up the observer when the flow is cancelled
        awaitClose {
            planetObserver?.close()
            planetObserver = null
        }
    }
}