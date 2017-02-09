heterarchy
==========

Cooperative multiple inheritance for CoffeeScript, à-la Python.

<a href="http://badge.fury.io/js/heterarchy"><img src="https://badge.fury.io/js/heterarchy.svg"/></a>
<a href="https://travis-ci.org/arximboldi/heterarchy"><img src="https://travis-ci.org/arximboldi/heterarchy.svg"/></a>
<a href="https://coveralls.io/r/arximboldi/heterarchy"><img src="https://coveralls.io/repos/arximboldi/heterarchy/badge.svg"/></a>

Adds multiple inheritance support to CoffeeScript (and JavaScript).
It uses the C3 linearization algorithm as described in the [famous
Dylan paper](http://192.220.96.201/dylan/linearization-oopsla96.html).

Example
-------

The library handles multiple inheritance and chains calls to `super`
in a linear order, solving the diamond problem and allowing for
[cooperative methods](http://www.artima.com/weblogs/viewpost.jsp?thread=281127). For
example, the following class heterarchy:

<div style="text-align:center">
  <img src="https://cdn.rawgit.com/arximboldi/heterarchy/master/pic/diamond.svg"/>
</div>

Can be implemented with the following code.

```coffee
{multi} = require 'heterarchy'

class A
    method: -> "A"

class B extends A
    method: -> "B > #{super}"

class C extends A
    method: -> "C > #{super}"

class D extends multi B, C
    method: -> "D > #{super}"
```

Calling `method` on a `D` instance would return the string `D > B > C > A`
showing the class linearization.

Documentation
-------------

### API

* [heterarchy][heterarchy]
  <br/>GitHub: [heterarchy.litcoffee](https://github.com/arximboldi/heterarchy/blob/master/heterarchy.litcoffee)

### Tests

* [spec.heterarchy][spec.heterarchy]
  <br/>GitHub: [heterarchy.spec.coffee](https://github.com/arximboldi/heterarchy/blob/master/test/heterarchy.spec.coffee)

  [heterarchy]: http://sinusoid.es/heterarchy/heterarchy.html
  [spec.heterarchy]: http://sinusoid.es/heterarchy/test/heterarchy.spec.html

Installation
------------

This is a standard [Node.JS](http://nodejs.org) module. One may
install the library with:

> npm install heterarchy

### In the browser

After cloning or downloading the repository you can create the browser version with

> make
 
This will create `browser.heterarchy.js` in the `lib/` folder.
Including the file in the browser will result in a global `heterarchy` variable that contains the normally exported functions.

Since the library requires `underscorejs` you must include it before `heterarchy` - or define 

```coffee
_ = {head, tail, map, find, some, without, isEmpty, every, memoize, reject, partial, isEqual, reduce}
```

#### Example

```html
<script type="text/javascript" src="path/to/underscore.js"></script>
<script type="text/javascript" src="path/to/browser.heterarchy.js"></script>
<script type="text/javascript" src="my_app.coffee"></script>
```

where `my_app.coffee` could be

```coffee
class A
    method: -> "A"

class B extends A
    method: -> "B > #{super}"

class C extends A
    method: -> "C > #{super}"

# note the heterarchy namespace
class D extends heterarchy.multi B, C
    method: -> "D > #{super}"
```


License
-------

*Heterarchy* is [Free Software][free-software] and is distributed
under the MIT license (see LICENSE).

  [free-software]: http://www.gnu.org/philosophy/free-sw.html

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
