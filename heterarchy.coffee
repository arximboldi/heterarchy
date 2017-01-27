initHeterarchy = (exports) ->
    {head, tail, map, find, some, without, isEmpty, every, memoize, reject,
     partial, isEqual} = _

    assert = (value, error) ->
        if not value
            throw new Error(if error? then error else "Assertion failed")

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

    copyOwn = (from, to, project = (x) -> x) ->
        for own key, value of from
            if not to.hasOwnProperty key
                to[key] = project value
        to

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

    merge = (inputs) ->
        while not isEmpty inputs
            next = find (map inputs, head), (candidate) ->
                every inputs, (input) -> candidate not in tail input
            assert next?, "Inconsistent multiple inheritance"
            inputs = reject map(inputs, (lst) -> without lst, next), isEmpty
            next

    isJavaScriptClass = (cls) ->
        return cls in [
            Array
            Boolean
            Date
            Error
            Function
            Number
            RegExp
            String
            Object
        ]

    exports.multi = (bases...) ->
        generate merge map(bases, mro).concat [bases]

    exports.mro = mro = (cls) ->
        if not cls? or not cls::?
            []
        else if not cls::hasOwnProperty '__mro__'
            result = [cls].concat mro inherited(cls)
            cls::__mro__ = result unless isJavaScriptClass cls
            result
        else
            cls::__mro__

    exports.inherited = inherited = (cls) ->
        Object.getPrototypeOf(cls.prototype)?.constructor

    exports.hierarchy = hierarchy = (cls) ->
        if not cls?
            []
        else
            [cls].concat hierarchy inherited cls

    exports.isinstance = (obj, classes...) ->
        exports.issubclass obj?.constructor, classes...

    exports.issubclass = (klass, classes...) ->
        linearization = mro klass
        some classes, (cls) -> cls in linearization

window.heterarchy = {}
initHeterarchy(window.heterarchy)
