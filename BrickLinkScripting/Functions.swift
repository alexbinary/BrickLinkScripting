
import Foundation



var durations: [TimeInterval] = []



func updatePriceOfAllInventories(withTypes itemTypes: [ItemType] = [], filter: @escaping (Inventory) -> Bool = { _ in true }, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping () -> Void) {
    
    durations = []
    
    print("Updating price of all inventories")
    print("Loading all inventories")
    
    getAllInventories(withTypes: itemTypes) { inventories in
        
        let filteredInventories = inventories.filter(filter)
        
        print("\(filteredInventories.count) inventories to update")
        
        updatePrice(ofAllInventoriesIn: filteredInventories.reversed(), toPriceGuide: priceGuidePath, withMultiplier: multiplier) {
    
            print("Done updating price of all inventories")
            completion()
        }
    }
}



func updatePrice(ofAllInventoriesIn inventories: [Inventory], toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping () -> Void) {

    print("\(inventories.count) inventories remaining")
    
    var reducedInventories = inventories
    if let inventory = reducedInventories.popLast() {
    
        let startTime = Date()
        
        updatePrice(of: inventory, toPriceGuide: priceGuidePath, withMultiplier: multiplier) { _ in
            
            let endTime = Date()
            let duration = startTime.distance(to: endTime)
            
            durations.append(duration)
            print("\(NSString(format:"%.2f", duration))s")
            
            let avgDuration = durations.reduce(TimeInterval(0), +) / Double(durations.count)
            let estimatedTotalRemainingDuration = avgDuration * Double(inventories.count-1)
            
            print("ETA \(format(estimatedTotalRemainingDuration))")
    
            updatePrice(ofAllInventoriesIn: reducedInventories, toPriceGuide: priceGuidePath, withMultiplier: multiplier, completion: completion)
        }
        
    } else {
        
        completion()
    }
}



func updatePrice(ofInventoryWithId inventoryId: String, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping (Inventory) -> Void) {
    
    getInventory(withId: inventoryId) { inventory in

        updatePrice(of: inventory, toPriceGuide: priceGuidePath, withMultiplier: multiplier) { updatedInventory in

            completion(updatedInventory)
        }
    }
}



func updatePrice(of inventory: Inventory, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping (Inventory) -> Void) {
    
    print("Updating price of \(inventory.item) to \(priceGuidePath) x\(multiplier)")
    print("Current price is \(inventory.unitPrice)")
    
    getPriceGuide(for: inventory, guideType: priceGuidePath.guideType, condition: priceGuidePath.condition) { priceGuide in
        
        print(priceGuide)

        let newPrice = priceGuide.value(forQuality: priceGuidePath.quality) * multiplier
        guard newPrice.floatValue != 0 else {
            
            print("No price data, inventory not updated")
            completion(inventory)
            return
        }
        
//        guard newPrice.floatValue > inventory.unitPrice.floatValue || inventory.unitPrice.floatValue == 100 else {
//            
//            print("Price guide value lower than current value, inventory not updated")
//            completion(inventory)
//            return
//        }
        
        var modifiedInventory = inventory
        modifiedInventory.unitPrice = FixedPointNumber(Float(Int(newPrice.floatValue * 1000))/1000)
        
        print("Updating price to \(modifiedInventory.unitPrice)")

        putInventory(modifiedInventory) { updatedInventory in

            print("New price is \(updatedInventory.unitPrice)")
            completion(updatedInventory)
        }
    }
}



func getPriceGuide(for inventory: Inventory, guideType: PriceGuideType, condition: ItemCondition, completion: @escaping (PriceGuide) -> Void) {

    let item = inventory.item
    let itemType = item.type
    let itemNo = item.no
    let colorId = inventory.colorId
    
    print("Checking cache for price guide for \(item) in color \(colorId), \(guideType) \(condition)")

    if let cacheResult = db.runForSingleValueResult("""
        SELECT avg_price FROM price_guide WHERE
            item_type = :item_type
        AND item_no = :item_no
        AND color_id = :color_id
        AND sold_or_stock = :sold_or_stock
        AND new_or_used = :new_or_used
        ORDER BY date DESC LIMIT 1
        """, with: [
            "item_type": itemType.rawValue,
            "item_no": itemNo,
            "color_id": "\(colorId)",
            "sold_or_stock": guideType.rawValue,
            "new_or_used": condition.databaseValue,
        ]
    ) {
        switch cacheResult {
        
        case .null:
            
            print("Cache MISS for price guide for \(item) in color \(colorId), \(guideType) \(condition)")
            
        case .value(let priceString):
            
            print("Cache HIT for price guide for \(item) in color \(colorId), \(guideType) \(condition): \(priceString)")
            
            if let priceFloat = Float(priceString) {
            
                completion(PriceGuide(minPrice: FixedPointNumber(0.0), maxPrice: FixedPointNumber(0.0), avgPrice: FixedPointNumber(priceFloat)))
                return
                
            } else {
                print("Failed to parse price: \(priceString)")
            }
        }
    } else {
        
        print("Cache MISS for price guide for \(item) in color \(colorId), \(guideType) \(condition) (no data)")
    }
    
    print("Loading price guide for \(item) in color \(colorId), \(guideType) \(condition)")
    
    let url = URL(string: "https://api.bricklink.com/api/store/v1/items/\(itemType)/\(itemNo)/price?color_id=\(colorId)&guide_type=\(guideType)&new_or_used=\(condition.rawValue)&currency_code=EUR")!

    var request = URLRequest(url: url)
    print("\(request.httpMethod!) \(request.url!)")

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!)

        let apiResponse: APIResponse<PriceGuide> = decodeAPIResponse(data)
        let priceGuide = apiResponse.data
        
        completion(priceGuide)
        
        print("Caching price guide for \(item) in color \(colorId), \(guideType) \(condition)")
        
        let dateFormatter = ISO8601DateFormatter()
        
        db.runIgnoringResult("""
            INSERT INTO price_guide(
                item_type,
                item_no,
                color_id,
                sold_or_stock,
                new_or_used,
                date,
                avg_price
            ) VALUES(
                :item_type,
                :item_no,
                :color_id,
                :sold_or_stock,
                :new_or_used,
                :date,
                :avg_price
            )
            """, with: [
                "item_type": itemType.rawValue,
                "item_no": itemNo,
                "color_id": "\(colorId)",
                "sold_or_stock": guideType.rawValue,
                "new_or_used": condition.databaseValue,
                "date": dateFormatter.string(from: Date()),
                "avg_price": "\(priceGuide.avgPrice)",
            ]
        )
    }
    .resume()
}



func putInventory(_ inventory: Inventory, completion: @escaping (Inventory) -> Void) {

    let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories/\(inventory.id)")!
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "PUT"
    request.httpBody = encodeForAPIRequest(inventory)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    print("\(request.httpMethod!) \(request.url!)")

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!)

        let apiResponse: APIResponse<Inventory> = decodeAPIResponse(data)
        let inventory = apiResponse.data

        completion(inventory)
    }
    .resume()
}



func getInventory(withId: String, completion: @escaping (Inventory) -> Void) {

    let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories/\(withId)")!
    
    var request = URLRequest(url: url)
    print("\(request.httpMethod!) \(request.url!)")

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!)

        let apiResponse: APIResponse<Inventory> = decodeAPIResponse(data)
        let inventory = apiResponse.data

        completion(inventory)
    }
    .resume()
}



func getAllInventories(withTypes itemTypes: [ItemType] = [], completion: @escaping ([Inventory]) -> Void) {

    var url = URL(string: "https://api.bricklink.com/api/store/v1/inventories")!
    
    if !itemTypes.isEmpty {
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components!.queryItems = [URLQueryItem(name: "item_type", value: itemTypes.map { $0.rawValue } .joined(separator: ","))]
        url = components!.url!
    }
    
    var request = URLRequest(url: url)
    print("\(request.httpMethod!) \(request.url!)")
    
    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!.prefix(1024))
        
        let apiResponse: APIResponse<[Inventory]> = decodeAPIResponse(data)
        let inventories = apiResponse.data

        completion(inventories)
    }
    .resume()
}
