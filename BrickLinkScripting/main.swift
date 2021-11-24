
import Foundation



let credentials = Credentials()



updatePriceOfAllInventories(
    withTypes: [.part],
    toPriceGuide: PriceGuidePath(guideType: .stock, condition: .new, quality: .avg),
    withMultiplier: 3,
    completion: {}
)

    

dispatchMain()
