
import Foundation



let credentials = Credentials()



let databasePath = FileManager.default.currentDirectoryPath.appending("/data.db")

var db = {
    
    DatabaseConnection(
        databasePath: databasePath,
        onCreate: createTables
    )
}()


func createTables(_ db: DatabaseConnection) {
    
    db.runIgnoringResult("""
        CREATE TABLE "price_guide" (
            item_type,
            item_no,
            color_id,
            sold_or_stock,
            new_or_used,
            date,
            avg_price
        );
        """
    )
}



updatePriceOfAllInventories(
    withTypes: [.part],
//    filter: { $0.dateCreated > "2022-05-01T05:00:00.000Z" },
    toPriceGuide: PriceGuidePath(guideType: .stock, condition: .new, quality: .avg),
    withMultiplier: 1.3,
    completion: {}
)

    

dispatchMain()
