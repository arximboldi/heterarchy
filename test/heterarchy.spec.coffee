# spec.heterarchy
# ===============
#
# > This file is part of [Heterarchy](http://sinusoid.es/heterarchy).
# > - **View me [on a static web](http://sinusoid.es/heterarchy/test/heterarchy.spec.html)**
# > - **View me [on GitHub](https://github.com/arximboldi/heterarchy/blob/master/test/heterarchy.spec.litcoffee)**
#
# Tests for multiple inheritance support.
#
# Most test heterarchies are taken from the [original C3
# paper](http://192.220.96.201/dylan/linearization-oopsla96.html)

chai = {expect} = require 'chai'
should = do chai.should

describe 'heterarchy', ->

    {multi, mro, hierarchy, inherited, isinstance, issubclass} =
        require '../heterarchy'

    # Hierarchies to test
    # -------------------
    #
    # Class heterarchy from the Dylan paper, figure 5. Make sure the
    # linearization respects the *Extended Precedence Graph*.

    class Pane
    class EditingMixin
    class EditablePane extends multi Pane, EditingMixin
    class ScrollingMixin
    class ScrollablePane extends multi Pane, ScrollingMixin
    class EditableScrollablePane extends multi ScrollablePane, EditablePane

    # Class heterarchy from the Dylan paper, figure 4. Example of
    # compatibility with CLOS.

    class ChoiceWidget
    class PopupMixin
    class Menu extends ChoiceWidget
    class NewPopupMenu extends multi Menu, PopupMixin, ChoiceWidget

    # Class heterarchy from the Dylan paper, figure 2.  Make sure
    # linearization is monotonic.

    class Boat
    class DayBoat extends Boat
    class WheelBoat extends Boat
    class EngineLess extends DayBoat
    class SmallMultiHull extends DayBoat
    class PedalWheelBoat extends multi EngineLess, WheelBoat
    class SmallCatamaran extends SmallMultiHull
    class Pedalo extends multi PedalWheelBoat, SmallCatamaran

    # Hierarchy of classes with methods and constructors that use
    # super.

    class A
        constructor: ->
            @a = 'a'
        method: -> "A"
        @method: -> "A"
        @overrideNoSuper: () -> "a"

    class B extends A
        constructor: ->
            super
            @b = 'b'
        method: -> "B>#{super}"
        @method: -> "B>#{super}"
        @overrideNoSuper: () -> "b"

    class C extends A
        constructor: ->
            super
            @c = 'c'
        method: -> "C>#{super}"
        @method: -> "C>#{super}"
        @overrideNoSuper: () -> "c"

    class D extends multi B, C
        constructor: ->
            super
            @d = 'd'
        method: -> "D>#{super}"
        @method: -> "D>#{super}"
        @overrideNoSuper: () -> "d"

    class E extends A
        constructor: ->
            super
            @e = 'e'
        method: -> "E>#{super}"
        @method: -> "E>#{super}"
        @overrideNoSuper: () -> "e"

    class F extends multi C, E
        constructor: ->
            super
            @f = 'f'
        method: -> "F>#{super}"
        @method: -> "F>#{super}"
        @overrideNoSuper: () -> "f"

    class G extends multi D, F
        constructor: ->
            super
            @g = 'g'
        method: -> "G>#{super}"
        @method: -> "G>#{super}"
        @overrideNoSuper: () -> "g"

    # Hierarchy of classes where classes that only inherit from
    # `object` magically get a superclass in a multiple inheritance
    # context.

    class Base1
        classProperty: 42
        constructor: ->
            @base1 = 'base1'

    class Base2
        classProperty: ->
            'something'
        constructor: ->
            @base2 = 'base2'

    class Deriv extends multi Base1, Base2
        constructor: ->
            super
            @deriv = 'deriv'

    # Tests
    # -----

    describe 'mro', ->

        it 'throws an error when trying to linearize non-linearizable class hierarchy', ->
            expect (A, B, C) ->
                class A
                class B extends A
                class C extends multi A, B
            .to.throw(Error)

        it 'generates empty linearization for arbitrary object', ->
            (mro {}).should.eql []

        it 'generates empty linearization for null object', ->
            (mro undefined).should.eql []
            (mro null).should.eql []

        it 'generates a monotonic linearization', ->
            (mro Pedalo).should.eql [
                Pedalo, PedalWheelBoat, EngineLess, SmallCatamaran,
                SmallMultiHull, DayBoat, WheelBoat, Boat, Object]

        it 'respects local precedence', ->
            (mro NewPopupMenu).should.eql [
                NewPopupMenu, Menu, PopupMixin, ChoiceWidget, Object]

        it 'respects the extended precedence graph', ->
            (mro EditableScrollablePane).should.eql [
                EditableScrollablePane, ScrollablePane, EditablePane,
                Pane, ScrollingMixin, EditingMixin, Object ]

    describe 'multi', ->

        describe 'instance methods', ->

            it 'calls super properly in multi case', ->
                obj = new D()
                (mro D).should.eql [D, B, C, A, Object]
                obj.method().should.equal 'D>B>C>A'

            it 'calls super properly in recursive multi case', ->
                obj = new G()
                (mro G).should.eql [G, D, B, F, C, E, A, Object]
                obj.method().should.equal 'G>D>B>F>C>E>A'

        describe 'class methods', ->

            it 'calls super properly in multi case', ->
                D.method().should.equal 'D>B>C>A'

            it 'calls super properly in recursive multi case', ->
                # method is overridden
                G.method().should.equal 'G>D>B>F>C>E>A'

                # closure for not overwriting the value of e.g. `A`
                ((A, B, C) ->
                    # method is not overridden
                    class A
                        @classMethod: () ->
                            return super() + 'Base1'

                    class B
                        @classMethod: () ->
                            return 'Base2'

                    class C extends multi A, B

                    C.classMethod().should.equal 'Base2Base1'
                )(0, 0, 0)

        it 'overrides class methods properly in recursive multi case', ->
            # exclude Object
            for cls in mro(G)[0...-1]
                cls.overrideNoSuper().should.equal cls.name.toLowerCase()

        it 'gets constructed properly', ->
            obj = new D()
            obj.d .should.equal 'd'
            obj.c .should.equal 'c'
            obj.b .should.equal 'b'
            obj.a .should.equal 'a'

        it 'can generates the original hierarchy when possible', ->
            (hierarchy D).should.not.eql mro D
            (hierarchy inherited D).should.not.eql mro(D)[1..]
            (hierarchy inherited inherited D).should.eql mro(D)[2..]

        it 'memoizes generated superclasses', ->
            (inherited D).should.equal multi B, C

        it 'throws error on inconsistent hierarchy', ->
            (-> multi D, C, B)
                .should.throw "Inconsistent multiple inheritance"

        it 'makes sure the next constructor after a root class', ->
            obj = new Deriv()
            obj.base1 .should.equal 'base1'
            obj.base2 .should.equal 'base2'
            obj.deriv .should.equal 'deriv'

        it 'allows access class properties', ->
            obj = new Deriv()
            obj.classProperty .should.equal 42

        it 'allows class properties to be set via object', ->
            obj = new Deriv()
            obj.classProperty = 12
            obj.classProperty .should.equal 12
            Deriv::classProperty .should.equal 42

        it 'does not polute core classes', ->
            should.not.exist Object::__mro__
            should.not.exist Function::__mro__
            should.not.exist Number::__mro__
            should.not.exist Boolean::__mro__
            should.not.exist String::__mro__

            if typeof Promise isnt "undefined"
                should.not.exist Promise::__mro__
            if typeof Map isnt "undefined"
                should.not.exist Map::__mro__
            if typeof Set isnt "undefined"
                should.not.exist Set::__mro__

        describe 'freezes class properties', ->
            # This is just a limitation of the approach and these
            # tests are here to document it.  Ideally we would get rid
            # of it in the future.
            it 'makes changes invisible to children', ->
                obj = new Deriv()
                Base1::classProperty = 12
                Deriv::classProperty .should.equal 42
                obj.classProperty .should.equal 42

            it 'makes new properties invisible to children', ->
                obj = new Deriv()
                Base1::newClassProperty = 'sth'
                should.not.exist Deriv::newClassProperty
                should.not.exist obj.newClassProperty


    describe 'isinstance', ->

        it 'checks the classes of an object even with multiple inheritance', ->
            (isinstance new D(), D).should.be.true
            (isinstance new D(), B).should.be.true
            (isinstance new D(), C).should.be.true
            (isinstance new D(), A).should.be.true
            (isinstance new D(), Object).should.be.true
            (isinstance new A(), Object).should.be.true
            (isinstance new Object(), A).should.be.false
            (isinstance new Pedalo(), D).should.be.false
            (isinstance new Pedalo(), A).should.be.false
            (isinstance new Pedalo(), SmallCatamaran).should.be.true

    describe 'issubclass', ->

        it 'checks the relationships of classes even with multiple inheritance', ->
            (issubclass D, D).should.be.true
            (issubclass D, B).should.be.true
            (issubclass D, C).should.be.true
            (issubclass D, A).should.be.true
            (issubclass D, Object).should.be.true
            (issubclass A, Object).should.be.true
            (issubclass Object, A).should.be.false
            (issubclass Pedalo, D).should.be.false
            (issubclass Pedalo, A).should.be.false
            (issubclass Pedalo, SmallCatamaran).should.be.true

# License
# -------
#
# > Copyright (c) 2013, 2015 Juan Pedro Bolivar Puente <raskolnikov@gnu.org>
# >
# > Permission is hereby granted, free of charge, to any person obtaining a copy
# > of this software and associated documentation files (the "Software"), to deal
# > in the Software without restriction, including without limitation the rights
# > to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# > copies of the Software, and to permit persons to whom the Software is
# > furnished to do so, subject to the following conditions:
# >
# > The above copyright notice and this permission notice shall be included in
# > all copies or substantial portions of the Software.
# >
# > THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# > IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# > FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# > AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# > LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# > OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# > THE SOFTWARE.
