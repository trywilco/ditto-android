import Combine
import DittoSwift
import Foundation
import SwiftUI

// MARK: - DittoService
@MainActor class DittoService: ObservableObject {
    var isStoreInitialized: Bool = false

    var ditto: Ditto?
    var dittoApp: DittoApp?
    var subscription: DittoSyncSubscription?
    var planetObserver: DittoStoreObserver?
    
    @Published var planets: [Planet] = []
    
    private init() {}

    static var shared = DittoService()

    func initializeStore(dittoApp: DittoApp) async throws {
        if !isStoreInitialized {

            // setup logging
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = .debug

            //cache state for future use
            self.dittoApp = dittoApp
            
            //
            //TODO:
            //used for dev environment only
            //
            let customAuthUrl = URL(
                string:
                    "https://\(dittoApp.appConfig.endpointUrl)"
            )
            let webSocketUrl =
                "wss://\(dittoApp.appConfig.endpointUrl)"

            //
            //TODO:
            // used for dev environment, remove when done testing
            // https://docs.ditto.live/sdk/latest/install-guides/swift#integrating-and-initializing-sync
            let identity = DittoIdentity.onlinePlayground(
                appID: dittoApp.appConfig.appId,
                token: dittoApp.appConfig.authToken,
                enableDittoCloudSync: false,
                customAuthURL: customAuthUrl
            )
            
            //
            //production code, uncommet once using production environment
            //
            
            /*
             let identity = DittoIdentity.onlinePlayground(
             appID: dittoApp.appConfig.appId,
             token: dittoApp.appConfig.authToken
             )
             */
            
            ditto = Ditto(identity: identity)

            //
            //TODO Remove once done using Dev environment
            //
            ditto?.updateTransportConfig(block: { config in
                config.connect.webSocketURLs.insert(webSocketUrl)
            })

            try setupSubscription()
            try registerObservers()
        }
    }
}

// MARK: Subscriptions
extension DittoService {

    /// Sets up the initial subscription to the planets collection in Ditto.
    /// 
    /// This subscription ensures that changes to the planets collection are synced 
    /// between the local Ditto store and the MongoDB Atlas database.
    /// 
    /// - SeeAlso: https://docs.ditto.live/sdk/latest/sync/syncing-data#creating-subscriptions
    /// 
    /// - Throws: A DittoError if the subscription cannot be created or started
    func setupSubscription() throws {
        if let dittoInstance = ditto {
            //setup subscription
            self.subscription = try dittoInstance.sync.registerSubscription(
                query: """
                    SELECT *
                    FROM planets
                    WHERE isArchived = :isArchived
                    """,
                arguments: ["isArchived": false])
            try dittoInstance.startSync()
        }
    }

    func stopSubscription() {
        if let subscriptionInstance = subscription {
            subscriptionInstance.cancel()
            ditto?.stopSync()
        }
    }
}

// MARK: Register Observer - Live Query
extension DittoService {

    /// Registers observers for the planets collection to handle real-time updates.
    /// 
    /// This method sets up a live query observer that:
    /// - Monitors the planets collection for changes
    /// - Updates the @Published planets array when changes occur
    /// - Orders planets by their distance from the sun
    /// - Filters out archived planets
    /// 
    /// - SeeAlso: https://docs.ditto.live/sdk/latest/crud/read#using-args-to-query-dynamic-values
    /// 
    /// - Throws: A DittoError if the observer cannot be registered
    func registerObservers() throws {
        if let dittoInstance = ditto {
            planetObserver = try dittoInstance.store.registerObserver(
                query: """
                    SELECT *
                    FROM planets
                    WHERE isArchived = :isArchived
                    ORDER BY orderFromSun
                    """,
                arguments: ["isArchived": false]
            ) { [weak self] results in
                Task { @MainActor in
                    // Create new Planet instances and update the published property
                    self?.planets = results.items.compactMap{ Planet(value: $0.value) }
                }
            }
        }
    }
}

// MARK: Planet Operations
extension DittoService {

    /// Updates an existing planet's properties in the Ditto store.
    /// 
    /// This method uses DQL to update all mutable fields of the planet 
    /// 
    /// - Parameter planet: The Planet object containing the updated values
    /// - SeeAlso: https://docs.ditto.live/sdk/latest/crud/update#updating
    /// 
    /// - Throws: A DittoError if the update operation fails
    func updatePlanet(_ planet: Planet) async throws {
        do {
            if let dittoInstance = ditto {
                try await dittoInstance.store.execute(
                    query: """
                    UPDATE planets
                    SET hasRings = :hasRings,
                        isArchived = :isArchived,
                        mainAtmosphere = :atmosphere,
                        name = :name,
                        orderFromSun = :orderFromSun,
                        surfaceTemperatureC = :temperature
                    WHERE planetId = :planetId
                """,
                    arguments: [
                        "hasRings": planet.hasRings,
                        "isArchived": planet.isArchived,
                        "atmosphere": planet.mainAtmosphere,
                        "name": planet.name,
                        "orderFromSun": planet.orderFromSun,
                        "planetId": planet.planetId,
                        "temperature": planet.surfaceTemperatureC.toDictionary(),
                    ]
                )
            }
        } catch {
            self.dittoApp?.setError(error)
        }
    }
    
    /// Creates a new planet document in the Ditto store.
    /// 
    /// This method:
    /// - Creates a new document in the planets collection
    /// - Assigns the provided ID and properties
    /// - Sets initial isArchived status to false
    /// 
    /// - Parameter planet: The planet to add to the store 
    /// - SeeAlso: https://docs.ditto.live/sdk/latest/crud/create#creating-documents
    /// 
    /// - Throws: A DittoError if the insert operation fails
    func addPlanet(_ planet: Planet) async throws {
        do {
            if let dittoInstance = ditto {
                try await dittoInstance.store.execute(
                    query: """
                    INSERT INTO planets
                    DOCUMENTS (:newPlanet)
                """,
                    arguments: ["newPlanet": [
                        "_id": planet._id,
                        "hasRings": planet.hasRings,
                        "isArchived": planet.isArchived,
                        "mainAtmosphere": planet.mainAtmosphere,
                        "name": planet.name,
                        "orderFromSun": planet.orderFromSun,
                        "planetId": planet.planetId,
                        "surfaceTemperatureC": planet.surfaceTemperatureC.toDictionary()
                        ]
                    ]
                )
            }
        } catch {
            self.dittoApp?.setError(error)
        }
    }
    
    /// Archives a planet by setting its isArchived flag to true.
    /// 
    /// This method implements the 'Soft-Delete' pattern, which:
    /// - Marks the planet as archived instead of deleting it
    /// - Removes it from active queries and views
    /// - Maintains the data for historical purposes
    /// 
    /// - Parameter planetId: The unique identifier of the planet to archive
    /// - SeeAlso: https://docs.ditto.live/sdk/latest/crud/delete#soft-delete-pattern
    /// 
    /// - Throws: A DittoError if the archive operation fails
    func archivePlanet(_ planetId: String) async throws {
        do {
            if let dittoInstance = ditto {
                try await dittoInstance.store.execute(
                    query: """
                    UPDATE planets
                    SET isArchived = :isArchived
                    WHERE planetId = :planetId
                """,
                    arguments: [
                        "isArchived": true,
                        "planetId": planetId,
                    ]
                )
            }
        } catch {
            self.dittoApp?.setError(error)
        }
    }
}
