import yajl/Yajl
import structs/[HashMap,ArrayList]

main: func {
    parser := SimpleParser new()
    parser parseAll("{\"one\": \"hello\", \"two\": \"world\", \"fun\": [1, 2, 3]}")
    value := parser getValue(HashMap<Value>)
    value get("one") value as String println()
    value get("two") value as String println()
    value get("fun") value as ArrayList<Value> get(1) value as Int toString() println()
}


