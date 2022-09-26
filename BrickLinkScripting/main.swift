
import Foundation



let credentials = Credentials()



updatePriceOfAllInventories(
    withTypes: [.part],
//    filter: { $0.dateCreated > "2022-05-01T05:00:00.000Z" },
    toPriceGuide: PriceGuidePath(guideType: .stock, condition: .new, quality: .avg),
    withMultiplier: 2,
    completion: {}
)

    

dispatchMain()
