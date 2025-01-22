//
//  DittoConfig.swift
//  Guides
//
//  Created by Aaron LaBeau on 1/21/25.
//

import Foundation

/// Store the app details to use when instantiating the app
struct AppConfig {
    var endpointUrl: String
    var appId: String
    var authToken: String
}

/// Read the dittoConfig.plist file and store the appId, endpointUrl, and authToken to use elsewhere.
func loadAppConfig() -> AppConfig {
    guard let path = Bundle.main.path(forResource: "dittoConfig", ofType: "plist") else {
        fatalError("Could not load dittoConfig.plist file!")
    }
    
    // Any errors here indicate that the dittoConfig.plist file has not been formatted properly.
    // Expected key/values:
    //      "endpointUrl": "your BigPeer Cloud URL Endpoint"
    //      "appId": "your BigPeer appId"
    //      "authToken": "your Online Playground Authentication Token"

    let data = NSData(contentsOfFile: path)! as Data
    let dittoConfigPropertyList = try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
    let endpointUrl = dittoConfigPropertyList["endpointUrl"]! as! String
    let appId = dittoConfigPropertyList["appId"]! as! String
    let authToken = dittoConfigPropertyList["authToken"]! as! String

    return AppConfig(
        endpointUrl: endpointUrl,
        appId: appId,
        authToken: authToken
    )
}
