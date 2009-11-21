import yajl/Yajl
import structs/[HashMap,ArrayList]

main: func {
    parser := SimpleParser new()
    parser parseAll("{\"one\": \"hello\", \"two\": \"world\", \"fun\": [1, 2, 3]}")
    map := parser getValue(ValueMap)
    map get("one", String) println()
    map get("two", String) println()
    map get("fun", ArrayList<Value<Int>>) get(1) value as Int toString() println()
}


