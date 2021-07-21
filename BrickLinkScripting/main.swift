//
//  main.swift
//  BrickLinkScripting
//
//  Created by Alexandre Bintz on 21/07/2021.
//

import Foundation

print("Hello, World!")





//
//
//
//
//import Foundation
//import Combine
//
//
//
//struct BrickLinkAPIClient {
//    
//    
//    let credentials: BrickLinkCredentials
//    
//    
//    init(with credentials: BrickLinkCredentials) {
//        
//        self.credentials = credentials
//    }
//    
//    
//    func getMyOrdersReceived() -> AnyPublisher<[Order], Never> {
//        
//        let url = URL(string: "https://api.bricklink.com/api/store/v1/orders?direction=in")!
//        
//        var request = URLRequest(url: url)
//        
//        request.addAuthentication(using: credentials)
//        
//        return getResponse(for: request)
//        
//            .map { (response: APIResponse<[Order]>) in
//            
//                let orders = response.data
//                
//                return orders
//            }
//        
//            .eraseToAnyPublisher()
//    }
//    
//    
//    func getMyInventories() -> AnyPublisher<[Inventory], Never> {
//        
//        let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories")!
//        
//        var request = URLRequest(url: url)
//        
//        request.addAuthentication(using: credentials)
//        
//        return getResponse(for: request)
//            
//            .map { (response: APIResponse<[Inventory]>) in
//                
//                let inventories = response.data
//                
//                return inventories
//            }
//            
//            .eraseToAnyPublisher()
//    }
//    
//    
//    func create(_ inventory: Inventory) -> AnyPublisher<Inventory, Never> {
//        
//        let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories")!
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = Data(encodingAsJSON: inventory)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        print(String(data: request.httpBody!, encoding: .utf8)!)
//        
//        request.addAuthentication(using: credentials)
//        
//        return getResponse(for: request)
//        
//            .map { (response: APIResponse<Inventory>) in
//                
//                let inventory = response.data
//                
//                return inventory
//            }
//            
//            .eraseToAnyPublisher()
//    }
//    
//    
//    func getPriceGuide(itemNo: String, colorId: Int) -> AnyPublisher<PriceGuide, Never> {
//        
//        let url = URL(string: "https://api.bricklink.com/api/store/v1/items/PART/\(itemNo)/price?color_id=\(colorId)&guide_type=sold&new_or_used=U&currency_code=EUR")!
//        
//        var request = URLRequest(url: url)
//        
//        request.addAuthentication(using: credentials)
//        
//        return getResponse(for: request)
//            
//            .map { (response: APIResponse<PriceGuide>) in
//                
//                let priceGuide = response.data
//                
//                return priceGuide
//            }
//            
//            .eraseToAnyPublisher()
//    }
//    
//    
//    func getColorList() -> AnyPublisher<[BrickLinkColor], Never> {
//        
//        let url = URL(string: "https://api.bricklink.com/api/store/v1/colors")!
//        
//        var request = URLRequest(url: url)
//        
//        request.addAuthentication(using: credentials)
//        
//        return getResponse(for: request)
//            
//            .map { (response: APIResponse<[BrickLinkColor]>) in
//                
//                let colors = response.data
//                
//                return colors
//            }
//            
//            .eraseToAnyPublisher()
//    }
//    
//    
//    func getResponse<T>(for request: URLRequest) -> AnyPublisher<T, Never> where T: Decodable {
//        
//        return Publishers.Future<T, Never> { promise in
//        
//            URLSession(configuration: .default).dataTask (with: request) { (data, response, error) in
//                
//                print(String(data: data!, encoding: .utf8)!)
//                
//                let decoded: T = data!.decode()
//                
//                promise(.success(decoded))
//                
//            } .resume()
//        }
//            
//        .eraseToAnyPublisher()
//    }
//}
//
//
//extension Data {
//    
//    init<T>(encodingAsJSON value: T) where T: Encodable {
//    
//        let encoder = JSONEncoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
//        
//        self = try! encoder.encode(value)
//    }
//    
//    func decode<T>() -> T where T: Decodable {
//        
//        let decoder = JSONDecoder()
//        
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        
//        let dateFormatter = ISO8601DateFormatter()
//        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
//        
//        decoder.dateDecodingStrategy = .custom({ (decoder) in
//            let stringValue = try! decoder.singleValueContainer().decode(String.self)
//            return dateFormatter.date(from: stringValue)!
//        })
//        
//        let decoded = try! decoder.decode(T.self, from: self)
//        
//        return decoded
//    }
//}
//
//
//
//
//
//
//
//
//
//import Foundation
//import CryptoSwift
//
//
//
///// See http://apidev.bricklink.com/redmine/projects/bricklink-api/wiki/Authorization
///// See https://oauth.net/core/1.0/
//
//
//
//extension URLRequest {
//    
//    
//    mutating func addAuthentication(using credentials: BrickLinkCredentials) {
//        
//        let authorizationHeader = buildAuthorizationHeader(using: credentials)
//        
//        addValue(authorizationHeader, forHTTPHeaderField: "Authorization")
//    }
//    
//    
//    func buildAuthorizationHeader(using credentials: BrickLinkCredentials) -> String {
//        
//        let oauthParameters = generateCompleteOAuthParameterSet(using: credentials)
//        
//        let headerValue = "OAuth " + oauthParameters.map { $0 + "=" + $1.urlEncoded!.quoted } .joined(separator: ",")
//        
//        return headerValue
//    }
//    
//    
//    func generateCompleteOAuthParameterSet(using credentials: BrickLinkCredentials) -> [String: String] {
//        
//        let baseParameterSet = [
//            
//            "oauth_consumer_key":
//                credentials.consumerKey,
//            
//            "oauth_token":
//                credentials.tokenValue,
//            
//            "oauth_signature_method":
//                "HMAC-SHA1",
//            
//            "oauth_timestamp":
//                "\(Int(Date().timeIntervalSince1970))",
//            
//            "oauth_nonce":
//                UUID().uuidString,
//            
//            "oauth_version":
//                "1.0",
//        ]
//        
//        let signature = generateSignature(using: baseParameterSet, with: credentials)
//        
//        let completeParameterSet = baseParameterSet.merging([
//            
//            "realm": "",
//            "oauth_signature": signature
//            
//        ], uniquingKeysWith: { (v1, v2) in v1 })
//        
//        return completeParameterSet
//    }
//    
//    
//    func generateSignature(using oauthParameters: [String: String], with credentials: BrickLinkCredentials) -> String {
//        
//        let signatureBaseString = buildSignatureBaseString(with: oauthParameters)
//        
//        let key = buildSigningKey(from: credentials)
//        
//        let signature = sign(signatureBaseString, with: key)
//        
//        return signature
//    }
//    
//    
//    func buildSignatureBaseString(with oauthParameters: [String: String]) -> String {
//        
//        let requestParameters = collectRequestParameters()
//        
//        let parametersForSignature = oauthParameters .merging(requestParameters, uniquingKeysWith: { (v1, v2) in v1 })
//        
//        let elements = [
//            
//            httpMethod!.uppercased(),
//            normalize(url!),
//            normalize(parametersForSignature),
//        ]
//        
//        let signatureBaseString = elements .map { $0.urlEncoded! } .joined(separator: "&")
//        
//        return signatureBaseString
//    }
//    
//    
//    func collectRequestParameters() -> [String: String] {
//        
//        var parameters: [String: String] = [:]
//        
//        URLComponents(url: url!, resolvingAgainstBaseURL: false)!
//            
//            .queryItems? .forEach { parameters[$0.name] = $0.value }
//        
//        return parameters
//    }
//    
//    
//    func normalize(_ url: URL) -> String {
//        
//        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
//        
//        urlComponents.query = nil
//        urlComponents.fragment = nil
//        
//        let normalizedUrl = urlComponents.url!.absoluteString
//        
//        return normalizedUrl
//    }
//    
//    
//    func normalize(_ requestParameters: [String: String]) -> String {
//        
//        let sorted = requestParameters .sorted { $0.key.compare($1.key) == .orderedAscending }
//        
//        let concatenated = sorted .map { $0.key + "=" + $0.value.urlEncoded! } .joined(separator: "&")
//        
//        return concatenated
//    }
//    
//    
//    func buildSigningKey(from credentials: BrickLinkCredentials) -> String {
//        
//        let key = [ credentials.consumerSecret, credentials.tokenSecret ]
//            
//            .map { $0.urlEncoded! } .joined(separator: "&")
//        
//        return key
//    }
//    
//    
//    func sign(_ signatureBaseString: String, with key: String) -> String {
//        
//        let digest = try! HMAC(key: key, variant: .sha1).authenticate(signatureBaseString.bytes)
//        
//        let signature = digest.toBase64()!
//        
//        return signature
//    }
//}
//
//
//
//private extension String {
//    
//    
//    var urlEncoded: String? {
//            
//        self.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"))
//    }
//    
//    
//    var quoted: String {
//        
//        return "\"" + self + "\""
//    }
//}
