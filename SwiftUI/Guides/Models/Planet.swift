import Foundation

@Observable
class Planet: Decodable {
    let _id: String
    let hasRings: Bool
    let isArchived: Bool
    let mainAtmosphere: [String]
    let name: String
    let orderFromSun: Int
    let planetId: String
    let surfaceTemperatureC: Temperature
    
    init (_id: String,
          hasRings: Bool,
          isArchived: Bool,
          mainAtmosphere: [String],
          name: String,
          orderFromSun: Int,
          planetId: String,
          surfaceTemperatureC: Temperature) {
        
        self._id = _id
        self.hasRings = hasRings
        self.isArchived = isArchived
        self.mainAtmosphere = mainAtmosphere
        self.name = name
        self.orderFromSun = orderFromSun
        self.planetId = planetId
        self.surfaceTemperatureC = surfaceTemperatureC
    }
    
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
            // Handle NSNumber values for temperatures
            let max: Double? = {
                if let number = temp["max"] as? NSNumber {
                    return number.doubleValue
                }
                return nil
            }()
            
            let mean: Double = {
                if let number = temp["mean"] as? NSNumber {
                    return number.doubleValue
                }
                return 0.0 // Default value since mean is non-optional
            }()
            
            let min: Double? = {
                if let number = temp["min"] as? NSNumber {
                    return number.doubleValue
                }
                return nil
            }()
            
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

@Observable
class Temperature: Decodable {
    let max: Double?
    let mean: Double
    let min: Double?
    
    init(max: Double?, mean: Double, min: Double?){
        self.max = max
        self.mean = mean
        self.min = min
    }
    
    func toDictionary() -> [String: Any?]{
        return ["max": max, "mean": mean, "min": min]
    }
}

