import UnQLite


let id = Expression<Int>("id")
let name = Expression<String>("name")
let qty = Expression<Int>("qty")
let price = Expression<Double>("price")
let isFour = Expression<Bool>("is_four")

let productsCount = 10
let products = (1...productsCount).map { i -> [ExpressionType: Any] in
    [id: i, name: "Prodict name \(i)", qty: i * 2, price: Double(i) * 1.5, isFour: i % 4 == 0]
}


do {
    let db = try Connection()

    let cl = try db.collection(with: "products")
    try cl.append(products)

    let result = try cl.filter(id == 1 || price * qty >= 300)
    result.forEach {
        print($0)
    }

//    try vm.setOutput { message in
//        print(">>> \(message)")
//    }
//    try vm.execute()
} catch {
    print(error)
}
