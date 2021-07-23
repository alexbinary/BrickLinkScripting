
import Foundation



let credentials = BrickLinkCredentials()

var priceGuideCache: [InventoryItem: [PriceGuideType: [ItemCondition: PriceGuide]]] = [:]



updatePriceOfAllInventories(toPriceGuide: PriceGuidePath(guideType: .stock, condition: .used, quality: .avg), withMultiplier: 1.1)

    

dispatchMain()
