
import Foundation



struct BrickLinkCredentials {

    
    let consumerKey: String = "5384025985CF43F391463885E5B033C6"
    let consumerSecret: String = "98FBCE8EF6DA4171BDF2DC5999B784C8"
    
    let tokenValue: String = "13353D8AF9874BF1858064FD9454CDBF"
    let tokenSecret: String = "1128A4EFCBCF46918E2AE818E26D5102"
}



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



struct InventoryItem: Codable {

    
    let type: ItemType
    let no: String
}



enum ItemType: String, Codable {
    
    case part = "PART"
    case minifig = "MINIFIG"
    case instruction = "INSTRUCTION"
    case set = "SET"
    case originalBox = "ORIGINAL_BOX"
    case gear = "GEAR"
}



enum ItemCondition: String, Codable {
    
    
    case new = "N"
    case used = "U"
}



struct PriceGuide: Decodable {

    
    let minPrice: FixedPointNumber
    let maxPrice: FixedPointNumber
    let avgPrice: FixedPointNumber
    
    
    func value(of v: PriceGuideValue) -> FixedPointNumber {
        
        switch v {
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



enum PriceGuideValue {
    
    
    case min
    case max
    case avg
}



struct FixedPointNumber: Codable, ExpressibleByFloatLiteral {
    
    
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
}


func *(lhs: FixedPointNumber, rhs: Float) -> FixedPointNumber {
    
    return FixedPointNumber(lhs.floatValue * rhs)
}
