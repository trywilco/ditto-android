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
            //
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

    // Live Query - used to update planets array
    // anytime the data changes in Ditto
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
