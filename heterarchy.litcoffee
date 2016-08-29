heterarchy
==========

> This file is part of [Heterarchy](http://sinusoid.es/heterarchy).
> - **View me [on a static web](http://sinusoid.es/heterarchy/heterarchy.html)**
> - **View me [on GitHub](https://github.com/arximboldi/heterarchy/blob/master/heterarchy.litcoffee)**

Adds multiple inheritance support to CoffeeScript (and JavaScript).
It uses the C3 linearization algorithm as described in the [famous
Dylan paper](http://192.220.96.201/dylan/linearization-oopsla96.html).

    {head, tail, map, find, some, without, isEmpty, every, memoize, reject,
     partial, isEqual, reduce} = require 'underscore'

    assert = (value, error) ->
        if not value
            throw new Error(if error? then error else "Assertion failed")

Multiple inheritance
--------------------

The **multi** function takes a list of classes and returns a *special*
class object that merges the class hierarchies, as linearized by the
C3 algorithm. Limitations of the approach are:

- `instanceof` does not always work as expected. For example:

  > ```coffee
  > class A
  > class B extends A
  > class C extends A
  > class D extends multi B, C
  > assert new D not instanceof B
  > ```

  Instead, one should use the provided `isinstance` function.

- Some of the bases of a multi-inherited hierarchy are *frozen* when
  the sub-class is defined -- i.e. later modifications to the
  superclass are not visible to the subclass or its instances.  For
  example, in the previous heterarchy:

  > ```coffee
  > B::newProperty = 42
  > assert D::newProperty == undefined
  > ```

The `multi` function memoizes its results such that identity is
maintained, implying `multi X, Y is multi X, Y`.

    exports.multi = (bases...) ->
        generate merge map(bases, mro).concat [bases]

This takes a list of classes representing a hierarchy (from most to
least derived) and generates a single-inheritance hierarchy that
behaves like a class that would be have such a hierarchy.

    generate = memoize (linearization) ->
        next = head linearization
        if isEqual linearization, hierarchy next
            next
        else
            class Result extends generate tail linearization
                __mro__: linearization
                constructor: reparent next, @, next::constructor
                copyOwn next, @
                copyOwn next::, @::, partial reparent, next, @

This utility lets us copy own properties of a *from* object that are
not own properties of a *to* object into the *to* object, optionally
transformed via a projection function.

    copyOwn = (from, to, project = (x) -> x) ->
        for own key, value of from
            if not to.hasOwnProperty key
                to[key] = project value
        to

Methods in CoffeeScript call super directly, so we have to change the
`__super__` attribute of the original class during the scope of the
method so it calls the right super of the linearization.  Also,
programmers don't call super in constructor of root classes --indeed
doing so would rise an error-- so we have to inject such a call when
there are classes after these in the linearization.  The **reparent**
function takes care of all these and given an original class, and the
new class that is replacing it a linearized heterarchy, returns a
wrapped copy of a value of the former that is suitable for replacing
it in the later.

    reparent = (oldklass, newklass, value) ->
        if value not instanceof Function
            value
        else if value is oldklass::constructor and inherited(oldklass) is Object
            superctor = inherited(newklass)::constructor
            ->
                superctor.apply @, arguments
                value.apply @, arguments
        else
            newsuper = inherited(newklass)::
            oldsuper = oldklass.__super__
            ->
                oldklass.__super__ = newsuper
                try
                    value.apply @, arguments
                finally
                    oldklass.__super__ = oldsuper

This is the C3 linearization algorithm, as translated from the
original paper.

    merge = (inputs) ->
        while not isEmpty inputs
            next = find (map inputs, head), (candidate) ->
                every inputs, (input) -> candidate not in tail input
            assert next?, "Inconsistent multiple inheritance"
            inputs = reject map(inputs, (lst) -> without lst, next), isEmpty
            next

Introspection
-------------

The **mro** function returns the method resolution order
(linearization) of a given class:

> ```coffee
> class A
> class B extends A
> class C extends B
> assert mro(C).equals [C, B, A]
> ```

It returns the original classes that were mixed in when used with
mult-inherited classes:

> ```coffee
> class A
> class B extends A
> class C extends A
> class D extends multi B, C
> assert mro(D).equals [D, B, C, A, Object]
> ```

    javaScriptClassNames = [
        "Array"
        "Boolean"
        "Date"
        "Error"
        "Function"
        "Number"
        "RegExp"
        "String"
        "Object"
        "EvalError"
        "RangeError"
        "ReferenceError"
        "SyntaxError"
        "TypeError"
        "URIError"
        # non-standard classes
        "Symbol"
        # typed arrays
        "Int8Array"
        "Uint8Array"
        "Uint8ClampedArray"
        "Int16Array"
        "Uint16Array"
        "Int32Array"
        "Uint32Array"
        "Float32Array"
        "Float64Array"
        # keyed Keyed collections
        "Map"
        "Set"
        "WeakMap"
        "WeakSet"
        # Structured data
        "ArrayBuffer"
        "DataView"
        # Control abstraction objects
        "Promise"
        "Generator"
        "GeneratorFunction"
        # Reflection
        "Reflect"
        "Proxy"
    ]
    javaScriptClasses = reduce javaScriptClassNames, (classes, name) ->
        classes[global[name]] = global[name]
        classes
    , {}
    isJavaScriptClass = (cls) ->
        javaScriptClasses[cls] is cls

    exports.mro = mro = (cls) ->
        if not cls? or not cls::?
            []
        else if not cls::hasOwnProperty '__mro__'
            result = [cls].concat mro inherited(cls)
            cls::__mro__ = result unless isJavaScriptClass cls
            result
        else
            cls::__mro__

The **inherited** function returns the CoffeeScript superclass of an
object, for example:

> ```coffee
> class A
> class B extends A
> assert inherited(B) == A
> ```

Note that for multiple inherited classes, this returns the mixed
object, not the next class in the MRO, as in:

> ```coffee
> class C extends multi A, B
> assert inherited(C) == multi(A, B)
> ```

    exports.inherited = inherited = (cls) ->
        Object.getPrototypeOf(cls.prototype)?.constructor

The **hierarchy** returns the CoffeeScript hierarchy of classes of a
given class, including the class itself.  For multiple inherited
classes, it may return speciall classes that were generated to produce
the flattening, as in:

> ```coffee
> class A
> class B extends A
> class C extends A
> class D extends multi B, C
> assert not mro(D).equals hierarchy(D)
> assert hierarchy(D).equals
>     [ D, multi(B, C), inherited(multi B, C), A, Object ]
> ```

    exports.hierarchy = hierarchy = (cls) ->
        if not cls?
            []
        else
            [cls].concat hierarchy inherited cls

The **isinstance** function takes an object and a class or classes and
returns whether the object is an instance of any of those classes. It
is compatible with multi-inherited classes.

    exports.isinstance = (obj, classes...) ->
        exports.issubclass obj?.constructor, classes...

The **issubclass** tells whether a class is a subtype of another type.

    exports.issubclass = (klass, classes...) ->
        linearization = mro klass
        some classes, (cls) -> cls in linearization

License
-------

> Copyright (c) 2013, 2015 Juan Pedro Bolivar Puente <raskolnikov@gnu.org>
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
