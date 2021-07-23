
import Foundation



struct APIResponse<T>: Decodable where T: Decodable {
    
    
    let data: T
}



struct Inventory: Codable, Identifiable {
    
    
    var id: Int { inventoryId }
    
    let inventoryId: Int
    let item: InventoryItem
    let colorId: Int
    var unitPrice: FixedPointNumber
}



struct InventoryItem: Codable, Hashable, CustomStringConvertible {

    
    let type: ItemType
    let no: String
    
    
    var description: String { "\(type)#\(no)" }
}



enum ItemType: String, Codable, CustomStringConvertible {
    
    
    case part = "PART"
    case minifig = "MINIFIG"
    case instruction = "INSTRUCTION"
    case set = "SET"
    case originalBox = "ORIGINAL_BOX"
    case gear = "GEAR"
    
    
    var description: String { self.rawValue }
}



enum ItemCondition: String, Codable {
    
    
    case new = "N"
    case used = "U"
}



struct PriceGuide: Decodable {

    
    let minPrice: FixedPointNumber
    let maxPrice: FixedPointNumber
    let avgPrice: FixedPointNumber
    
    
    func value(forQuality quality: PriceGuideQuality) -> FixedPointNumber {
        
        switch quality {
        case .min: return self.minPrice
        case .max: return self.maxPrice
        case .avg: return self.avgPrice
        }
    }
}



enum PriceGuideType: String {
    
    
    case sold = "sold"
    case stock = "stock"
}



enum PriceGuideQuality {
    
    
    case min
    case max
    case avg
}



struct PriceGuidePath: Hashable, CustomStringConvertible {
    
    
    let guideType: PriceGuideType
    let condition: ItemCondition
    let quality: PriceGuideQuality
    
    
    var description: String { "PriceGuide(\(guideType), \(condition), \(quality))" }
}



struct FixedPointNumber: Codable, ExpressibleByFloatLiteral, CustomStringConvertible {
    
    
    typealias FloatLiteralType = Float
    
    
    init(floatLiteral value: FloatLiteralType) {
    
        self.floatValue = value
    }
    
    
    init(_ float: Float) {
    
        self.floatValue = float
    }
    
    
    var floatValue: Float
    
    
    init(from decoder: Decoder) throws {
        
        let stringValue = try! decoder.singleValueContainer().decode(String.self)
        self.floatValue = Float(stringValue)!
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try! container.encode(self.floatValue)
    }
    
    
    var description: String { "\(floatValue)" }
}


func *(lhs: FixedPointNumber, rhs: Float) -> FixedPointNumber {
    
    return FixedPointNumber(lhs.floatValue * rhs)
}
