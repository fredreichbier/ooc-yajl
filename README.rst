ooc-yajl
========

ooc-yajl is an `ooc <http://ooc-lang.org>`_ binding to
`yet another json library <http://lloyd.github.com/yajl/>`_ by
`lloyd <http://github.com/lloyd>`_ - thanks for the great library!

ooc-yajl is capable of JSON parsing and generation.

ooc-yajl is licensed under the MIT license (see LICENSE for details).

Usage
-----

Usage of ooc-yajl is quite simple and abstracted. See `simple-test.ooc`
for - well, yeah, a simple test.

First, let's import the package. To make it clearer where all the names
come from, we're using a namespaced import here::

    import yajl/Yajl into JSON

You can now use a simple shortcut for JSON parsing from a string::

    str := "{\"key\":\"value\",\"list\":[1,\"2\",[3]]}"
    map := JSON parse(str, ValueMap)

This line gets a ``ValueMap`` object (you pass the root object's type to ``parse``).
You can be sure that the returning object is a ``ValueMap`` object,
since ooc-yajl performs a type check.

ooc-yajl uses ooc's standard types for all normal datatypes
(Int, Bool, String, ...), except for objects (maps) and arrays
There are the ``ValueMap`` and ``ValueList`` classes for this, which in
fact are simple subclasses of ``HashMap`` and ``ArrayList``.

You should also know that ooc-yajl internally uses a container class
for all values called ``Value``. ``ValueMap`` and ``ValueList`` internally
store ``Value`` instances which store the actual values. To retrieve the
actual value, not the container ``Value``, make sure you use the ``getValue``
and ``setValue`` methods or the special operators.
All ``get*`` methods perform type checks.

.. note:: Umm no, currently I have disabled the type checks. I have to think about that.

::

    map getValue("key", String)
    // is equivalent to
    map["key", String]

    map putValue("foo", "bar")
    // is equivalent to
    map["foo"] = "bar"

    array getValue(1, String)
    // is equivalent to
    array[1, String]

Let's continue with our example now. You now got a nice ``ValueMap`` object. To get
its members, do this::

    // gets the "key" value as String.
    myValue := map["key", String]
    // or get the "list" value as ValueList.
    myList := map["list", JSON ValueList]
    // this will fail with a ``JSON JSONException``, since you passed the wrong type:
    myInt := map["list", Int]
    // you can, of course, also handle lists:
    myFirstElement := myList[0, Int]

You see, parsing is easy, let's go to generation. Basically, you can just build your own
ooc-yajl object structure like the one you receive from ``parse`` and call ``generate``
on it::

    str := JSON generate(map)

Let's see how'd construct JSON manually::

    info := JSON ValueMap new()
    info["real_name"] = "John Doe"
    info["age"] = 56
    info["is_cool"] = true
    
    secretNames := JSON ValueList new()
    secretNames addValue("Herbert YouHaveNoIdeaWhoIAmCauseIGotACoupleOfSecretNames") .addValue("Dohn Joe") .addValue(009)
    info["secret_names"] = secretNames

    // and now, generate it!
    string := JSON generate(info)
    string println()

Yay.

If you have any questions, please join #ooc-lang on freenode and ask. You are loved.
