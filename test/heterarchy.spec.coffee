# spec.heterarchy
# ===============
#
# Tests for multiple inheritance support.
#
# Most test heterarchies are taken from the [original C3
# paper](http://192.220.96.201/dylan/linearization-oopsla96.html)

{expect} = require 'chai'

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

    class B extends A
        constructor: ->
            super
            @b = 'b'
        method: -> "B>#{super}"

    class C extends A
        constructor: ->
            super
            @c = 'c'
        method: -> "C>#{super}"

    class D extends multi B, C
        constructor: ->
            super
            @d = 'd'
        method: -> "D>#{super}"

    class E extends A
        constructor: ->
            super
            @e = 'e'
        method: -> "E>#{super}"

    class F extends multi C, E
        constructor: ->
            super
            @f = 'f'
        method: -> "F>#{super}"

    class G extends multi D, F
        constructor: ->
            super
            @g = 'g'
        method: -> "G>#{super}"

    # Hierarchy of classes where classes that only inherit from
    # `object` magically get a superclass in a multiple inheritance
    # context.

    class Base1
        constructor: ->
            @base1 = 'base1'

    class Base2
        constructor: ->
            @base2 = 'base2'

    class Deriv extends multi Base1, Base2
        constructor: ->
            super
            @deriv = 'deriv'

    # Tests
    # -----

    describe 'mro', ->

        it 'generates empty linearization for arbitrary object', ->
            expect(mro {}).to.eql []

        it 'generates empty linearization for null object', ->
            expect(mro undefined).to.eql []
            expect(mro null).to.eql []

        it 'generates a monotonic linearization', ->
            expect(mro Pedalo).to.eql [
                Pedalo, PedalWheelBoat, EngineLess, SmallCatamaran,
                SmallMultiHull, DayBoat, WheelBoat, Boat, Object]

        it 'respects local precedence', ->
            expect(mro NewPopupMenu).to.eql [
                NewPopupMenu, Menu, PopupMixin, ChoiceWidget, Object]

        it 'respects the extended precedence graph', ->
            expect(mro EditableScrollablePane).to.eql [
                EditableScrollablePane, ScrollablePane, EditablePane,
                Pane, ScrollingMixin, EditingMixin, Object ]

    describe 'multi', ->

        it 'calls super properly in multi case', ->
            obj = new D
            expect(mro D).to.eql [D, B, C, A, Object]
            expect(obj.method()).to.equal "D>B>C>A"

        it 'calls super properly in recursive multi case', ->
            obj = new G
            expect(mro G).to.eql [G, D, B, F, C, E, A, Object]
            expect(obj.method()).to.equal "G>D>B>F>C>E>A"

        it 'gets constructed properly', ->
            obj = new D
            expect(obj.d).to.equal 'd'
            expect(obj.c).to.equal 'c'
            expect(obj.b).to.equal 'b'
            expect(obj.a).to.equal 'a'

        it 'can generates the original hierarchy when possible', ->
            expect(hierarchy D).not.to.eql mro D
            expect(hierarchy inherited D).not.to.eql mro(D)[1..]
            expect(hierarchy inherited inherited D).to.eql mro(D)[2..]

        it 'it memoizes generated superclasses', ->
            expect(inherited D).to.equal multi B, C

        it 'throws error on inconsistent hierarchy', ->
            expect(-> multi D, C, B)
                .to.throw "Inconsistent multiple inheritance"

        it 'makes sure the next constructor after a root class', ->
            obj = new Deriv
            expect(obj.base1).to.equal 'base1'
            expect(obj.base2).to.equal 'base2'
            expect(obj.deriv).to.equal 'deriv'

    describe 'isinstance', ->

        it 'checks the classes of an object even with multiple inheritance', ->
            expect(isinstance new D, D).to.be.true
            expect(isinstance new D, B).to.be.true
            expect(isinstance new D, C).to.be.true
            expect(isinstance new D, A).to.be.true
            expect(isinstance new D, Object).to.be.true
            expect(isinstance new A, Object).to.be.true
            expect(isinstance new Object, A).to.be.false
            expect(isinstance new Pedalo, D).to.be.false
            expect(isinstance new Pedalo, A).to.be.false
            expect(isinstance new Pedalo, SmallCatamaran).to.be.true

    describe 'issubclass', ->

        it 'checks the relationships of classes even with multiple inheritance', ->
            expect(issubclass D, D).to.be.true
            expect(issubclass D, B).to.be.true
            expect(issubclass D, C).to.be.true
            expect(issubclass D, A).to.be.true
            expect(issubclass D, Object).to.be.true
            expect(issubclass A, Object).to.be.true
            expect(issubclass Object, A).to.be.false
            expect(issubclass Pedalo, D).to.be.false
            expect(issubclass Pedalo, A).to.be.false
            expect(issubclass Pedalo, SmallCatamaran).to.be.true

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
