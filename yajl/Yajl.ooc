use yajl

import structs/[ArrayList,HashMap]

Callbacks: cover from yajl_callbacks {
    null_: extern(yajl_null) Func
    boolean: extern(yajl_boolean) Func
    integer: extern(yajl_integer) Func
    double_: extern(yajl_double) Func
    number: extern(yajl_number) Func
    string: extern(yajl_string) Func
    startMap: extern(yajl_start_map) Func
    mapKey: extern(yajl_map_key) Func
    endMap: extern(yajl_end_map) Func
    startArray: extern(yajl_start_array) Func
    endArray: extern(yajl_end_array) Func
}

ValueMap: class extends HashMap<Value<Pointer>> {
    init: func ~valueMap {
        T = Value
        super()
    }
    
    get: func ~typed <T> (index: String, T: Class) -> T {
        get(index) value
    }
}

ValueList: class extends ArrayList<Value<Pointer>> {
    init: func ~valueList {
        T = Value
        super()
    }
    
    get: func ~typed <T> (index: Int, T: Class) -> T {
        get(index) value
    }
}

Status: cover from Int

ParserConfig: cover from yajl_parser_config {
    allowComments, checkUTF8: extern UInt
}

AllocFuncs: cover from yajl_alloc_funcs {
    malloc, realloc, free: extern Func
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
    ctx as ValueList add(Value<ValueMap> new(ValueMap, ValueMap new()))
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
    /* get the index of the last ValueMap */
    while(i >= 0){
        if(arr get(i) getType() == ValueType MAP) {
            break
        }
        i -= 1
    }
    hashmap := arr get(i) value as ValueMap
    i += 1
    while(i < arr size()) {
        key := arr get(i) value as String
        hashmap put(key, arr get(i + 1))
        arr removeAt(i) .removeAt(i)
    }
    return -1
}

_startArrayCallback: func (ctx: Pointer) -> Int {
    ctx as ValueList add(Value<ValueList> new(ValueList, ValueList new()))
    return -1
}

_endArrayCallback: func (ctx: Pointer) -> Int {
    arr := ctx as ValueList
    i := arr lastIndex()
    /* get the index of the last ArrayList */
    while(1){
        value := arr get(i)
        if(value getType() == ValueType ARRAY) {
            break
        }
        i -= 1
    }
    value := arr get(i) value as ValueList 
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

    complete: func -> Status {
        yajl_parse_complete(handle)
        /* TODO: clear `stack` */
    }

    getValue: func <T> (T: Class) -> T {
        v := stack get(stack size() - 1) as Value<Pointer>
        v value
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
    
    init: func (type: Class, value: T) {
        this value = value
        this type = type
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
}

yajl_alloc: extern func (Callbacks*, ParserConfig*, AllocFuncs*, Pointer) -> Handle
yajl_parse: extern func (Handle, UChar*, UInt) -> Status
yajl_parse_complete: extern func (Handle) -> Status
