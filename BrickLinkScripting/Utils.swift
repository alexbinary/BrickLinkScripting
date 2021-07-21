
import Foundation



func decodeAPIResponse<T>(_ data: Data) -> T where T: Decodable {
        
    let decoder = JSONDecoder()
    
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let decoded = try! decoder.decode(T.self, from: data)
    
    return decoded
}



func encodeForAPIRequest<T>(_ value: T) -> Data where T: Encodable {

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    return try! encoder.encode(value)
}
