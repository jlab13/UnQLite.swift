import Foundation
import UnQLite


let id = Expression<Int>("product.id")
let product = Expression<Int>("product")
let str = Expression<String>("bla bla")

(str + "zzz").raw
