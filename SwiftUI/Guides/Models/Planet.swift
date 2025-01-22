import Foundation

struct Planet: Decodable {
    let _id: String
    let _mdb: MDB
    let hasRings: Bool
    let isArchived: Bool
    let mainAtmosphere: [String]
    let name: String
    let orderFromSun: Double
    let planetId: String
    let surfaceTemperatureC: Temperature
    
    struct MDB: Decodable {
        let _id: String
        let ct: [Int]
        let tm: TM
        
        struct TM: Decodable {
            let _id: Int
        }
    }
    
    struct Temperature: Decodable {
        let max: Double?
        let mean: Double
        let min: Double?
    }
} 
