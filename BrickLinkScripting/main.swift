
import Foundation



let credentials = Credentials()



updatePriceOfAllInventories(withTypes: [.part, .minifig], toPriceGuide: PriceGuidePath(guideType: .stock, condition: .new, quality: .avg), withMultiplier: 1) {}

    

dispatchMain()
