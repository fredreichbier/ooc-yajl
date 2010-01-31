import yajl/Yajl
import structs/[HashMap,ArrayList]

main: func {
    map := ValueMap new()
    map putValue("key", "value")
    list := ValueList new()
    list addValue(1)
    list addValue("2")
    list2 := ValueList new()
    list2 addValue(3) .addValue(4.0)
    list addValue(list2)
    map putValue("list", list)
    value := Value<ValueMap> new(ValueMap, map)
    value generate() println()
}


