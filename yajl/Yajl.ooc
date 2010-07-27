use yajl

import structs/[ArrayList,HashMap]
import io/Reader
import text/Buffer

Callbacks: cover from yajl_callbacks {
    null_: extern(yajl_null) Pointer
    boolean: extern(yajl_boolean) Pointer
    integer: extern(yajl_integer) Pointer
    double_: extern(yajl_double) Pointer
    number: extern(yajl_number) Pointer
    string: extern(yajl_string) Pointer
    startMap: extern(yajl_start_map) Pointer
    mapKey: extern(yajl_map_key) Pointer
    endMap: extern(yajl_end_map) Pointer
    startArray: extern(yajl_start_array) Pointer
    endArray: extern(yajl_end_array) Pointer
}

JSONException: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}

ValueMap: class extends HashMap<String, Value<Pointer>> {
    init: func ~valueMap {
        K = String
        V = Value<Pointer>
        super()
    }

    get: func ~typed <T> (index: String, T: Class) -> T {
        container := get(index)
/*        if(!container type inheritsFrom?(T)) {
            JSONException new("%s expected, got %s" format(T name, container type name)) throw()
        }*/
        container value
    }

    getType: func (index: String) -> Class {
        get(index) type
    }

    putValue: func <T> (key: String, value: T) {
        v := Value<T> new(T, value)
        put(key, v as Value<Pointer>)
    }

    getValue: func <T> (index: String, T: Class) -> T {
        get(index, T)
    }
}

operator [] <T> (this: ValueMap, key: String, T: Class) -> T {
    this getValue(key, T)
}

operator []= <T> (this: ValueMap, key: String, value: T) {
    this putValue(key, value)
}

ValueList: class extends ArrayList<Value<Pointer>> {
    init: func ~valueList {
        T = String
        super()
    }

    get: func ~typed <T> (index: Int, T: Class) -> T {
        get(index) value
    }

    getType: func (index: Int) -> Class {
        get(index) type
    }

    addValue: func <T> (value: T) {
        v := Value<T> new(T, value)
        add(v)
    }

    getValue: func <T> (index: Int, T: Class) -> T {
        container := get(index)
/*        if(!container type inheritsFrom?(T)) {
            JSONException new("%s expected, got %s" format(T name, container type name)) throw()
        }*/
        container value
    }
}

operator [] <T> (this: ValueList, index: Int, T: Class) -> T {
    this getValue(index, T)
}

Status: cover from Int

ParserConfig: cover from yajl_parser_config {
    allowComments, checkUTF8: extern UInt
}

AllocFuncs: cover from yajl_alloc_funcs {
    malloc, realloc, free: extern Pointer
    ctx: extern Pointer
}

_malloc: func (ctx: Pointer, sz: UInt) -> Pointer {
    gc_malloc(sz)
}

_realloc: func (ctx, ptr: Pointer, sz: UInt) -> Pointer {
    gc_realloc(ptr, sz)
}

_free: func (ctx, ptr: Pointer) {
    /* do nothing. */
}

_nullCallback: func (ctx: Pointer) -> Int {
    ctx as ValueList add(Value<Pointer> new(Pointer, null))
    return -1
}

_booleanCallback: func (ctx: Pointer, value: Int) -> Int {
    ctx as ValueList add(Value<Bool> new(Bool, value ? true : false))
    return -1
}

_intCallback: func (ctx: Pointer, value: Long) -> Int {
    ctx as ValueList add(Value<Int> new(Int, value))
    return -1
}

_doubleCallback: func (ctx: Pointer, value: Double) -> Int {
    ctx as ValueList add(Value<Double> new(Double, value))
    return -1
}

/* TODO: Number callback! */

_stringCallback: func (ctx: Pointer, value: const UChar*, len: UInt) -> Int {
    s := String new(len)
    memcpy(s, value, len)
    s[len] = 0
    ctx as ValueList add(Value<String> new(String, s))
    return -1
}

_startMapCallback: func (ctx: Pointer) -> Int {
    ctx as ValueList add(Value<ValueMap> new(ValueMap, ValueMap new(), false))
    return -1
}

_mapKeyCallback: func (ctx: Pointer, key: const UChar*, len: UInt) -> Int {
    s := String new(len)
    memcpy(s, key, len)
    s[len] = 0
    ctx as ValueList add(Value<String> new(String, s))
    return -1
}

_endMapCallback: func (ctx: Pointer) -> Int {
    arr := ctx as ValueList
    i := arr lastIndex()
    /* get the index of the last incomplete ValueMap.
       Why incomplete?
       ValueMaps could also appear as values.
     */
    while(i >= 0){
        if(arr get(i) getType() == ValueType MAP && !arr get(i) complete) {
            break
        }
        i -= 1
    }
    hashmap := arr get(i) value as ValueMap
    arr get(i) complete = true
    i += 1
    while(i < arr size()) {
        key := arr get(i) value as String
        hashmap put(key, arr get(i + 1))
        arr removeAt(i) .removeAt(i)
    }
    return -1
}

_startArrayCallback: func (ctx: Pointer) -> Int {
    ctx as ValueList add(Value<ValueList> new(ValueList, ValueList new(), false))
    return -1
}

_endArrayCallback: func (ctx: Pointer) -> Int {
    arr := ctx as ValueList
    i := arr lastIndex()
    /* get the index of the last incomplete ArrayList */
    while(1){
        value := arr get(i)
        if(value getType() == ValueType ARRAY && !value complete) {
            break
        }
        i -= 1
    }
    value := arr get(i) value as ValueList
    arr get(i) complete = true
    i += 1
    while(i < arr size()) {
        value add(arr get(i))
        arr removeAt(i)
    }
    return -1
}

_callbacks: Callbacks
_callbacks null_ = _nullCallback
_callbacks boolean = _booleanCallback
_callbacks integer = _intCallback
_callbacks double_ = _doubleCallback
_callbacks string = _stringCallback
_callbacks startMap = _startMapCallback
_callbacks mapKey = _mapKeyCallback
_callbacks endMap = _endMapCallback
_callbacks startArray = _startArrayCallback
_callbacks endArray = _endArrayCallback

_config: ParserConfig
_allocFuncs: AllocFuncs
_allocFuncs malloc = _malloc
_allocFuncs realloc = _realloc
_allocFuncs free = _free

Handle: cover from yajl_handle {
    new: static func (callbacks: Callbacks@, config: ParserConfig@, allocFuncs: AllocFuncs@, ctx: Pointer) -> This {
        yajl_alloc(callbacks&, config&, allocFuncs&, ctx)
    }

    new: static func ~lazy (ctx: Pointer) -> This {
        yajl_alloc(_callbacks&, _config&, _allocFuncs&, ctx)
    }
}

GenConfig: cover from yajl_gen_config {
    beautify: extern UInt
    indentString: extern const String

    new: static func (.beautify, .indentString) -> This {
        genConfig: GenConfig
        genConfig beautify = beautify
        genConfig indentString = indentString
        genConfig
    }
}

GenStatus: cover from Int

Gen: cover from yajl_gen {
    new: static func (config: GenConfig@, allocFuncs: AllocFuncs@) -> This {
        yajl_gen_alloc(config&, allocFuncs&)
    }

    new: static func ~lazy -> This {
        yajl_gen_alloc(null, _allocFuncs&) /* Yeah, actually, we can pass NULL here, though it seems to be undocumented behaviour. */
    }

    new: static func ~withCallback (callback: Func, config: GenConfig@, allocFuncs: AllocFuncs@, ctx: Pointer) -> This {
        // FIXME: if 'callback' is a real closure, we miss the context and bad things happen.
        // this is a design problem in ooc-yajl imho, but I'm not sur how to fix it since
        // where it's used it also takes additionnal arguments :/
        yajl_gen_alloc2(callback as Closure thunk, config&, allocFuncs&, ctx)
    }

    new: static func ~withCallbackLazy (callback: Func, ctx: Pointer) -> This {
        // FIXME: if 'callback' is a real closure, we miss the context and bad things happen.
        // this is a design problem in ooc-yajl imho, but I'm not sur how to fix it since
        // where it's used it also takes additionnal arguments :/
        yajl_gen_alloc2(callback as Closure thunk, null, _allocFuncs&, ctx)
    }

    free: func {
        yajl_gen_free(this)
    }

    genInteger: extern(yajl_gen_integer) func (number: Int) -> GenStatus
    genDouble: extern(yajl_gen_double) func (number: Double) -> GenStatus
    genNumber: extern(yajl_gen_number) func (num: const UChar*, len: UInt) -> GenStatus
    genString: extern(yajl_gen_string) func (num: const UChar*, len: UInt) -> GenStatus
    genNull: extern(yajl_gen_null) func -> GenStatus
    genBool: extern(yajl_gen_bool) func (value: Bool) -> GenStatus
    genMapOpen: extern(yajl_gen_map_open) func -> GenStatus
    genMapClose: extern(yajl_gen_map_close) func -> GenStatus
    genArrayOpen: extern(yajl_gen_array_open) func -> GenStatus
    genArrayClose: extern(yajl_gen_array_close) func -> GenStatus
    getBuf: extern(yajl_gen_get_buf) func (buf: const String*, len: UInt) -> GenStatus
    clear: extern(yajl_gen_clear) func
}

SimpleParser: class {
    handle: Handle
    stack: ValueList

    init: func {
        stack = ValueList new()
        handle = Handle new(stack as Pointer)
    }

    parse: func (text: String, length: UInt) -> Status {
        yajl_parse(handle, text as UChar*, length)
    }

    parse: func ~lazy (text: String) -> Status {
        parse(text, text length())
    }

    parseAll: func (text: String, length: UInt) -> Status {
        parse(text, length)
        complete()
    }

    parseAll: func ~lazy (text: String) -> Status {
        parseAll(text, text length())
    }

    parseAll: func ~reader (reader: Reader) {
        BUFFER_SIZE := const 30
        chars := String new(BUFFER_SIZE)
        while(reader hasNext?()) {
            parse(chars, reader read(chars, 0, BUFFER_SIZE))
        }
    }

    complete: func -> Status {
        yajl_parse_complete(handle)
        /* TODO: clear `stack` */
    }

    getValue: func -> Value<Pointer> {
        stack get(stack size() - 1) as Value<Pointer>
    }

    getValue: func ~typed <T> (T: Class) -> T {
        container := stack get(stack size() - 1)
        if(!container type inheritsFrom?(T)) {
            JSONException new("%s expected, got %s" format(T name, container type name)) throw()
        }
        container value as T
    }
}

ValueType: class {
    NULL_: static const Int = 1
    BOOLEAN: static const Int = 2
    INTEGER: static const Int = 3
    DOUBLE: static const Int = 4
    NUMBER: static const Int = 5
    STRING: static const Int = 6
    MAP: static const Int = 7
    ARRAY: static const Int = 8
}

Value: class <T> {
    value: T
    type: Class
    complete: Bool

    init: func (=type, =value, =complete) {}
    init: func ~lazy (.type, .value) {
        init(type, value, false)
    }

    getType: func -> Int {
        return match type {
            case ValueMap => ValueType MAP
            case ValueList => ValueType ARRAY
            case Pointer => ValueType NULL_
            case Bool => ValueType BOOLEAN
            case Int => ValueType INTEGER
            case Double => ValueType DOUBLE
            /* TODO: what about NUMBER? */
            case String => ValueType STRING
        }
    }

    _generate: func (gen: Gen) {
        match type {
            case ValueMap => {
                gen genMapOpen()
                for(key: String in value as ValueMap getKeys()) {
                    gen genString(key, key length())
                    value as ValueMap get(key) _generate(gen)
                }
                gen genMapClose()
            }
            case ValueList => {
                gen genArrayOpen()
                for(con: Value<Pointer> in value as ValueList) {
                    con _generate(gen)
                }
                gen genArrayClose()
            }
            case Pointer => {
                gen genNull()
            }
            case Bool => {
                gen genBool(value as Bool)
            }
            case Int => {
                gen genInteger(value as Int)
            }
            case Double => {
                gen genDouble(value as Double)
            }
            case String => {
                gen genString(value as String, (value as String) length())
            }
            /* TODO: what about NUMBER? */
        }
    }

    generate: func ~withConfig (beautify: Bool, indent: String) -> String {
        buf := Buffer new()
        config := GenConfig new(beautify as UInt, indent)
        gen := Gen new(func (buffer: Buffer, s: String, len: UInt) { buffer append(s, len) }, config&, _allocFuncs&, buf)
        _generate(gen)
        buf toString()
    }

    generate: func ~beautify (beautify: Bool) -> String {
        generate(beautify, null)
    }

    generate: func ~lazy -> String {
        generate(false, null)
    }
}

yajl_alloc: extern func (Callbacks*, ParserConfig*, AllocFuncs*, Pointer) -> Handle
yajl_gen_alloc: extern func (GenConfig*, AllocFuncs*) -> Gen
yajl_gen_alloc2: extern func (Pointer, GenConfig*, AllocFuncs*, Pointer) -> Gen
yajl_gen_free: extern func (Gen)
yajl_parse: extern func (Handle, UChar*, UInt) -> Status
yajl_parse_complete: extern func (Handle) -> Status

generate: func <T> (v: T) -> String {
    Value<T> new(T, v) generate()
}

parse: func <T> (s: String, T: Class) -> T {
    SimpleParser new() parseAll(s) .getValue(T)
}
