class window.Base1
    @classMethod: () ->
        return super() + "Base1"

    init: () ->
        return super() + "Base1"


class window.Base2
    @classMethod: () ->
        return "Base2"

    init: () ->
        return "Base2"


class window.Deriv extends heterarchy.multi Base1, Base2

    @classMethod: () ->
        return super() + "Deriv"

    init: () ->
        return super() + "Deriv"

class window.A
    constructor: ->
        @a = 'a'
    method: -> "A"
    @method: -> "A"
    @overrideNoSuper: () -> "a"

class window.B extends A
    constructor: ->
        super
        @b = 'b'
    method: -> "B>#{super}"
    @method: -> "B>#{super}"
    @overrideNoSuper: () -> "b"

class window.C extends A
    constructor: ->
        super
        @c = 'c'
    method: -> "C>#{super}"
    @method: -> "C>#{super}"
    @overrideNoSuper: () -> "c"

class window.D extends heterarchy.multi B, C
    constructor: ->
        super
        @d = 'd'
    method: -> "D>#{super}"
    @method: -> "D>#{super}"
    @overrideNoSuper: () -> "d"

class window.E extends A
    constructor: ->
        super
        @e = 'e'
    method: -> "E>#{super}"
    @method: -> "E>#{super}"
    @overrideNoSuper: () -> "e"

class window.F extends heterarchy.multi C, E
    constructor: ->
        super
        @f = 'f'
    method: -> "F>#{super}"
    @method: -> "F>#{super}"
    @overrideNoSuper: () -> "f"

class window.G extends heterarchy.multi D, F
    constructor: ->
        super
        @g = 'g'
    method: -> "G>#{super}"
    @method: -> "G>#{super}"
    @overrideNoSuper: () -> "g"
