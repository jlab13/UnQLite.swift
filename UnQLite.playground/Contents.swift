import Foundation
import UnQLite


let id = Expression<Int>("product.id")
let product = Expression<Int>("product")


let e = product == 4
e.raw

let u = URL(string: "http://test.org/test")!
u.appendingPathComponent("path1sdf")
