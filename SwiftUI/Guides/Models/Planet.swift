import Foundation

struct Planet: Decodable {
    let _id: String
    let hasRings: Bool
    let isArchived: Bool
    let mainAtmosphere: [String]
    let name: String
    let orderFromSun: Int
    let planetId: String
    let surfaceTemperatureC: Temperature
    
    struct Temperature: Decodable {
        let max: Double?
        let mean: Double
        let min: Double?
    }
}

extension Planet {
    init(value: [String: Any?]) {
        _id = value["_id"] as! String
        hasRings = value["hasRings"] as! Bool
        isArchived = value["isArchived"] as! Bool
        mainAtmosphere = value["mainAtmosphere"] as! [String]
        name = value["name"] as! String
        orderFromSun = value["orderFromSun"] as! Int
        planetId = value["planetId"] as! String
        
        // Safely unwrap the temperature dictionary
        if let temp = value["surfaceTemperatureC"] as? [String: Any] {
            // Now we can safely access the temperature values
            let max = temp["max"] as? Double
            let min = temp["min"] as? Double
            let mean = temp["mean"] as? Double ?? 0.0  // Provide default value since mean is non-optional
            surfaceTemperatureC = Temperature(
                max: max,
                mean: mean,
                min: min
            )
        } else {
            // Provide default values if temperature data is missing
            surfaceTemperatureC = Temperature(
                max: nil,
                mean: 0.0,
                min: nil
            )
        }
    }
}
