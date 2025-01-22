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

    func initializeStore(dittoApp: DittoApp) async throws {
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
            //used for dev environment only
            //remove when done testing
            //
            let customAuthUrl = URL(
                string:
                    "https://\(dittoApp.appConfig.appId).cloud-dev.ditto.live"
            )
            let webSocketUrl =
                "wss://\(dittoApp.appConfig.appId).cloud-dev.ditto.live"

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
            
            //production code, uncommet once using production environment
            
            /*
             let identity = DittoIdentity.onlinePlayground(
             appID: dittoApp.appConfig.appId,
             token: dittoApp.appConfig.authToken
             )
             */
            
            ditto = Ditto(
                identity: identity, persistenceDirectory: persistenceDirURL)

            //TODO Remove once done using Dev environment
            ditto?.updateTransportConfig(block: { config in
                config.connect.webSocketURLs.insert(webSocketUrl)
            })

            try setupSubscription()
            try await self.loadData()
            try registerObservers()
            
            //TODO remove loading mock data once calling ditto code is fixed
            try await loadMockData()
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
                results.items.forEach {
                    print($0)
                }
            }
        }
    }

}

// MARK: Initial Dataload
extension DittoService {

    func loadData() async throws {
        if let dittoInstance = ditto {
            let results = try await dittoInstance.store.execute(
                query: """
                    SELECT *
                    FROM planets
                    WHERE isArchived = :isArchived
                    """,
                arguments: ["isArchived": false])

            results.items.forEach {
                print($0)
            }
        }
    }

    func loadMockData() async throws {
        let jsonData = """
            [
            {
                "_id": "621ff30d2a3e781873fcb65c",
                "_mdb": {
                    "_id": "621ff30d2a3e781873fcb65c",
                    "ct": [1737496378, 184],
                    "tm": {"_id": 7}
                },
                "hasRings": true,
                "isArchived": false,
                "mainAtmosphere": [],
                "name": "Mercury",
                "orderFromSun": 1,
                "planetId": "621ff30d2a3e781873fcb65c",
                "surfaceTemperatureC": {
                    "max": 427,
                    "mean": 67,
                    "min": -173
                }
            },
            {
                "_id": "621ff30d2a3e781873fcb65d",
                "_mdb": {
                    "_id": "621ff30d2a3e781873fcb65d",
                    "ct": [1737496378, 185],
                    "tm": {"_id": 7}
                },
                "hasRings": true,
                "isArchived": false,
                "mainAtmosphere": [
                    "H2",
                    "He",
                    "CH4"
                ],
                "name": "Uranus",
                "orderFromSun": 7,
                "planetId": "621ff30d2a3e781873fcb65d",
                "surfaceTemperatureC": {
                    "max": null,
                    "mean": -197.2,
                    "min": null
                }
            },
            {
                "_id": "621ff30d2a3e781873fcb65e",
                "_mdb": {
                    "_id": "621ff30d2a3e781873fcb65e",
                    "ct": [1737496378, 186],
                    "tm": {"_id": 7}
                },
                "hasRings": false,
                "isArchived": false,
                "mainAtmosphere": [
                    "SO2",
                    "O2",
                    "SO"
                ],
                "name": "Io",
                "orderFromSun": 5.2,
                "planetId": "621ff30d2a3e781873fcb65e",
                "surfaceTemperatureC": {
                    "max": -130,
                    "mean": -163,
                    "min": -183
                }
            }
            ]
            """
        
        guard let data = jsonData.data(using: .utf8) else {
            throw NSError(domain: "JSONError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
        
        let decoder = JSONDecoder()
        let results = try decoder.decode([Planet].self, from: data)
        self.planets = results
    }

}

// MARK: Planet Operations
extension DittoService {
    func addPlanet(_ planet: Planet) async throws {
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
                    "mdb": planet._mdb,
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
    }
    
    func updatePlanet(_ planet: Planet) async throws {
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
    }
    
    func archivePlanet(_ planet: Planet) async throws {
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
    }
}
