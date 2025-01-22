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
    var planets: [Planet] = []
    
    private init() {}

    static var shared = DittoService()

    func initializeStore(dittoApp: DittoApp) async throws n {
        if !isStoreInitialized {

            // setup logging
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = .debug

            //cache state for future use
            self.dittoApp = dittoApp
            
            #if os(tvOS)
                let directory: FileManager.SearchPathDirectory =
                    .cachesDirectory
            #else
                let directory: FileManager.SearchPathDirectory =
                    .documentDirectory
            #endif

            let persistenceDirURL = try? FileManager()
                .url(
                    for: directory, in: .userDomainMask, appropriateFor: nil,
                    create: true
                )
                .appendingPathComponent("ditto-guides")

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
            
            ditto = Ditto(
                identity: identity, persistenceDirectory: persistenceDirURL)

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

// MARK: Register Observer
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
                    """,
                arguments: ["isArchived": false]
            ) { results in
                //provide dictionary of items returned back into a map,
                //then create each item by calling init and storing in array
                self.planets = results.items.compactMap{ Planet(value: $0.value) }
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
                    SET _id = :id,
                        _mdb = :mdb,
                        hasRings = :hasRings,
                        isArchived = :isArchived,
                        mainAtmosphere = :atmosphere,
                        name = :name,
                        orderFromSun = :orderFromSun,
                        planetId = :planetId,
                        surfaceTemperatureC = :temperature
                """,
                    arguments: [
                        "id": planet._id,
                        "hasRings": planet.hasRings,
                        "isArchived": planet.isArchived,
                        "atmosphere": planet.mainAtmosphere,
                        "name": planet.name,
                        "orderFromSun": planet.orderFromSun,
                        "planetId": planet.planetId,
                        "temperature": planet.surfaceTemperatureC
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
                        "temperature": planet.surfaceTemperatureC
                    ]
                )
            }
        } catch {
            self.dittoApp?.setError(error)
        }
    }
    
    func archivePlanet(_ planet: Planet) async throws {
        do {
            if let dittoInstance = ditto {
                try await dittoInstance.store.execute(
                    query: """
                    UPDATE planets
                    SET isArchived = :isArchived,
                    WHERE planetId = :planetId
                """,
                    arguments: [
                        "isArchived": true,
                        "planetId": planet.planetId,
                    ]
                )
            }
        } catch {
            self.dittoApp?.setError(error)
        }
    }
}
