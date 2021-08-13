
import Foundation



let credentials = Credentials()



updatePriceOfAllInventories(
    withTypes: [.part],
    filter: { ($0.remarks ?? "").isEmpty },
    toPriceGuide: PriceGuidePath(guideType: .stock, condition: .new, quality: .avg),
    withMultiplier: 2,
    completion: {}
)

    

dispatchMain()
