import yajl/Yajl
import structs/[HashMap,ArrayList]

main: func {
    parser := SimpleParser new()
    parser parseAll("{\"one\": \"hello\", \"two\": \"world\", \"fun\": [1, 2, 3]}")
    value := parser getValue(ValueMap)
    /*value get("one", String) println()
    value get("two", String) println()
    value get("fun", ArrayList<Value>) get(1) value as Int toString() println()*/
}


