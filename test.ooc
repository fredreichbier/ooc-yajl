import yajl/Yajl
import structs/HashMap

main: func {
    parser := SimpleParser new()
    parser parseAll("{\"yay\": \"HELLO WORLD!\"}")
    value := parser getValue(HashMap<Value>)
//    value get("yay") value as String println()
}


