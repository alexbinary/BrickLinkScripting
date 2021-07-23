
import Foundation



let credentials = BrickLinkCredentials()


var priceGuideCache: [InventoryItem: [PriceGuideType: [ItemCondition: PriceGuide]]] = [:]





updatePriceOfAllInventories(toPriceGuide: PriceGuidePath(guideType: .stock, condition: .used, quality: .avg), withMultiplier: 1.1)



//updatePrice(ofInventoryWithId: "255534269", toPriceGuide: PriceGuidePath(guideType: .stock, condition: .used, quality: .avg), withMultiplier: 1.1) { updatedInventory in
//
//    print(updatedInventory)
//    print(updatedInventory.unitPrice)
//}



func updatePriceOfAllInventories(toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float) {
    
    getAllInventories { inventories in
        
        let iterator = inventories.makeIterator()
    
        updatePrice(ofAllRemainingInventoriesIn: iterator, toPriceGuide: priceGuidePath, withMultiplier: multiplier) {
    
            print("Done")
        }
    }
}



func updatePrice(ofAllRemainingInventoriesIn iterator: IndexingIterator<[Inventory]>, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping () -> Void) {

    var it = iterator
    
    if let inventory = it.next() {
    
        updatePrice(of: inventory, toPriceGuide: priceGuidePath, withMultiplier: multiplier) { updatedInventory in
    
            print(updatedInventory)
            print(updatedInventory.unitPrice)
            
            updatePrice(ofAllRemainingInventoriesIn: iterator, toPriceGuide: priceGuidePath, withMultiplier: multiplier, completion: completion)
        }
        
    } else {
        
        completion()
    }
}



func updatePrice(ofInventoryWithId inventoryId: String, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping (Inventory) -> Void) {
    
    getInventory(withId: inventoryId) { inventory in

        print(inventory)
        print(inventory.unitPrice)

        updatePrice(of: inventory, toPriceGuide: priceGuidePath, withMultiplier: multiplier) { updatedInventory in

            print(updatedInventory)
            print(updatedInventory.unitPrice)
        }
    }
}



func updatePrice(of inventory: Inventory, toPriceGuide priceGuidePath: PriceGuidePath, withMultiplier multiplier: Float, completion: @escaping (Inventory) -> Void) {
    
    getPriceGuide(for: inventory, guideType: priceGuidePath.guideType, condition: priceGuidePath.condition) { priceGuide in

        print(priceGuide)
        print(priceGuide.avgPrice)

        var modifiedInventory = inventory
        modifiedInventory.unitPrice = priceGuide.value(forQuality: priceGuidePath.quality) * multiplier
        print(modifiedInventory.unitPrice)

        putInventory(modifiedInventory) { updatedInventory in

            print(updatedInventory)
            print(updatedInventory.unitPrice)
            
            completion(updatedInventory)
        }
    }
}



func getPriceGuide(for inventory: Inventory, guideType: PriceGuideType, condition: ItemCondition, completion: @escaping (PriceGuide) -> Void) {
    
    let item = inventory.item
    let itemType = item.type
    let itemNo = item.no
    let colorId = inventory.colorId
    
    if let priceGuide = priceGuideCache[item]?[guideType]?[condition] {
        
        print("Using price guide from cache")
        completion(priceGuide)
        return
    }
    
    let url = URL(string: "https://api.bricklink.com/api/store/v1/items/\(itemType)/\(itemNo)/price?color_id=\(colorId)&guide_type=\(guideType)&new_or_used=\(condition.rawValue)&currency_code=EUR")!
    print(url)

    var request = URLRequest(url: url)

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!)

        let apiResponse: APIResponse<PriceGuide> = decodeAPIResponse(data)
        print(apiResponse)

        let priceGuide = apiResponse.data
        print(priceGuide)
        
        if priceGuideCache[item] == nil { priceGuideCache[item] = [:] }
        if priceGuideCache[item]![guideType] == nil { priceGuideCache[item]![guideType] = [:] }
        priceGuideCache[item]![guideType]![condition] = priceGuide
        
        completion(priceGuide)
    }
    .resume()
}



func putInventory(_ inventory: Inventory, completion: @escaping (Inventory) -> Void) {

    let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories/\(inventory.id)")!
    print(url)
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "PUT"
    request.httpBody = encodeForAPIRequest(inventory)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!)

        let apiResponse: APIResponse<Inventory> = decodeAPIResponse(data)
        print(apiResponse)

        let inventory = apiResponse.data
        print(inventory)

        completion(inventory)
    }
    .resume()
}



func getInventory(withId: String, completion: @escaping (Inventory) -> Void) {

    let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories/\(withId)")!
    print(url)
    
    var request = URLRequest(url: url)

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!)

        let apiResponse: APIResponse<Inventory> = decodeAPIResponse(data)
        print(apiResponse)

        let inventory = apiResponse.data
        print(inventory)

        completion(inventory)
    }
    .resume()
}



func getAllInventories(completion: @escaping ([Inventory]) -> Void) {

    let url = URL(string: "https://api.bricklink.com/api/store/v1/inventories")!
    print(url)
    
    var request = URLRequest(url: url)

    request.addAuthentication(using: credentials)

    URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in

        guard let data = data else { fatalError("request data was nil") }
        print(String(data: data, encoding: .utf8)!.prefix(1024))

        let apiResponse: APIResponse<[Inventory]> = decodeAPIResponse(data)
//        print(apiResponse)

        let inventories = apiResponse.data
//        print(inventories)

        completion(inventories)
    }
    .resume()
}

    

dispatchMain()
