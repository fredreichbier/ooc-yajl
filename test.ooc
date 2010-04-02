import yajl/Yajl into JSON
import structs/[HashMap,ArrayList]

testGeneration: func -> String {
    map := JSON ValueMap new()
    map["key"] = "value"

    list := JSON ValueList new()
    list addValue(1) .addValue("2")

    anotherList := JSON ValueList new()
    anotherList addValue(3) .addValue(4.0)
    
    list addValue(anotherList)

    map["list"] = list
    JSON generate(map)
}

testParsing: func (s: String) -> JSON ValueMap {
    JSON parse(s, JSON ValueMap)
}

main: func {
    s := testGeneration()
    s println()
    JSON generate(testParsing(s)) println()
}


