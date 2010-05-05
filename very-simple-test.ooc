import yajl/Yajl
import structs/[HashMap,ArrayList]

testGeneration: func -> String {
    map := ValueMap new()
    map["key"] = "value"

    list := ValueList new()
    list addValue(1) .addValue("2")

    anotherList := ValueList new()
    anotherList addValue(3) .addValue(4.0)
    
    list addValue(anotherList)

    map["list"] = list
    generate(map)
}

testParsing: func (s: String) -> ValueMap {
    parse(s, ValueMap)
}

main: func {
    s := testGeneration()
    s println()
    generate(testParsing(s)) println()
    // Let's fail!
    parse("1", ValueList)
}
