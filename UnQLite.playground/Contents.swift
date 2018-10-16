import UnQLite

let id = Expression<Int>("id")
let name = Expression<String>("name")
let qty = Expression<Int>("qty")
let price = Expression<Double>("price")
let isFour = Expression<Bool>("is_four")

let productsCount = 10
let productsData: [[String: Any]] = (1...productsCount).map {
    ["id": $0, "name": "Product Name \($0)", "qty": $0 * 2, "price": Double($0) * 1.5, "is_four": $0 % 4 == 0]
}

let db = try! Connection()
let clProducts = try! db.collection(with: "products")
try! clProducts.append(productsData)

let result = try clProducts.filter(name.contains("name 1"))
print(result)




//let script = """
//$zRec = [
//    {name: 'james', age: 27, mail: 'dude@example.com'},
//    {name: 'robert', age: 35, mail: 'rob@example.com'},
//    {name: 'monji', age: 47, mail: 'monji@example.com'},
//    {name: 'barzini', age: 52, mail: 'barz@mobster.com'}
//];
//
//db_create('users');
//db_store('users', $zRec);
//
//$zCallback = function($rec) {
//    return strpos($rec.name, "zin");
//};
//
//$data = db_fetch_all('users',$zCallback);
//print $data;
//
//"""
//
//do {
//    let db = try Connection()
//    let vm = try db.vm(with: script)
//    try vm.setOutput { str in
//        print(">> \(str)")
//    }
//
//    try vm.execute()
//} catch {
//    print(error)
//}
//
