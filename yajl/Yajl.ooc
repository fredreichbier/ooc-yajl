use yajl/yajl

import structs/[ArrayList,HashMap]

Callbacks: cover from yajl_callbacks {
    null_: extern(yajl_null) Func
    boolean: extern(yajl_boolean) Func
    integer: extern(yajl_integer) Func
    double: extern(yajl_double) Func
    number: extern(yajl_number) Func
    string: extern(yajl_string) Func
    startMap: extern(yajl_start_map) Func
    mapKey: extern(yajl_map_key) Func
    endMap: extern(yajl_end_map) Func
    startArray: extern(yajl_start_array) Func
    endArray: extern(yajl_end_array) Func
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
    ctx as ArrayList<Value> add(Value<Pointer> new(null))
    return -1
}

_booleanCallback: func (ctx: Pointer, value: Int) -> Int {
    ctx as ArrayList<Value> add(Value<Bool> new(value ? true : false))
    return -1
}

_intCallback: func (ctx: Pointer, value: Long) -> Int {
    ctx as ArrayList<Value> add(Value<Int> new(value))
    return -1
}

_doubleCallback: func (ctx: Pointer, value: Double) -> Int {
    ctx as ArrayList<Value> add(Value<Double> new(value))
    return -1
}

/* TODO: Number callback! */

_stringCallback: func (ctx: Pointer, value: const UChar*, len: UInt) -> Int {
    s := gc_malloc(Char size * len + 1) as String
    memcpy(s, value, len)
    s[len] = 0
    ctx as ArrayList<Value> add(Value<String> new(s))
    return -1
}

_startMapCallback: func (ctx: Pointer) -> Int {
    ctx as ArrayList<Value> add(Value<HashMap> new(HashMap<Value> new()))
    Value<HashMap> new(HashMap<Value> new()) T name println()
    return -1
}

_mapKeyCallback: func (ctx: Pointer, key: const UChar*, len: UInt) -> Int {
    s := gc_malloc(Char size * len + 1) as String
    memcpy(s, key, len)
    s[len] = 0
    ctx as ArrayList<Value> add(Value<String> new(s))
    return -1
}

_endMapCallback: func (ctx: Pointer) -> Int {
    arr := ctx as ArrayList<Value>
    i := arr size() - 1
    "~~" println()
    arr get(0) T name println()
    /* get the index of the last HashMap */
    while(arr get(i) getType() != ValueType MAP) {
       arr get(i) getType() toString() println()
        i -= 1
    }
    hashmap := arr get(i) value as HashMap
    while(i > arr size()) {
        arr size() toString() println()
        key := arr get(i) value as String
        hashmap put(key, arr get(i + 1))
        arr remove(i) .remove(i + 1)
    }
    return -1
}

_callbacks: Callbacks
_callbacks null_ = _nullCallback
_callbacks boolean = _booleanCallback
_callbacks integer = _intCallback
_callbacks double = _doubleCallback
_callbacks string = _stringCallback
_callbacks startMap = _startMapCallback
_callbacks mapKey = _mapKeyCallback
_callbacks endMap = _endMapCallback

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
    stack: ArrayList<Value>

    init: func {
        stack = ArrayList<Value> new()
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
        return stack get(stack size() - 1) value
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
    
    init: func (value: T) {
        this value = value
    }

    getType: func -> Int {
        //return match value class {
		return match T {
            case Pointer => ValueType NULL_
            case Bool => ValueType BOOLEAN
            case Int => ValueType INTEGER
            case Double => ValueType DOUBLE
            /* TODO: what about NUMBER? */
            case String => ValueType STRING
            case HashMap => ValueType MAP
            case ArrayList => ValueType ARRAY
        }
    }
}

yajl_alloc: extern func (Callbacks*, ParserConfig*, AllocFuncs*, Pointer) -> Handle
yajl_parse: extern func (Handle, UChar*, UInt) -> Status
yajl_parse_complete: extern func (Handle) -> Status
