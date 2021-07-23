
import Foundation



func updatePriceOfAllInventories(toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float) {
    
    print("Updating price of all inventories")
    
    getAllInventories { inventories in
        
        let iterator = inventories.makeIterator()
    
        updatePrice(ofAllRemainingInventoriesIn: iterator, toPriceGuide: priceGuidePath, withMultiplier: multiplier) {
    
            print("Done updating price of all inventories")
        }
    }
}



func updatePrice(ofAllRemainingInventoriesIn iterator: IndexingIterator<[Inventory]>, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping () -> Void) {

    var it = iterator
    
    if let inventory = it.next() {
    
        updatePrice(of: inventory, toPriceGuide: priceGuidePath, withMultiplier: multiplier) { _ in
    
            updatePrice(ofAllRemainingInventoriesIn: it, toPriceGuide: priceGuidePath, withMultiplier: multiplier, completion: completion)
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

        var modifiedInventory = inventory
        modifiedInventory.unitPrice = priceGuide.value(forQuality: priceGuidePath.quality) * multiplier

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



func getAllInventories(completion: @escaping ([Inventory]) -> Void) {

    let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories")!
    
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
