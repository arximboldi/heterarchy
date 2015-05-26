heterarchy
==========

Cooperative multiple inheritance for CoffeeScript, á-la Python.

[![build status](https://secure.travis-ci.org/arximboldi/heterarchy.svg)]
(https://travis-ci.org/arximboldi/heterarchy)

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

Calling `method` on a `D` instance would return the string `D > C > B > A`
showing the class linearization.

Documentation
-------------

### API

* [heterarchy][heterarchy]
  <br/>GitHub: [heterarchy.litcoffe](https://github.com/arximboldi/heterarchy/blob/master/heterarchy.litcoffee)

### Tests

* [spec.heterarchy][spec.heterarchy]
  <br/>GitHub: [heterarchy.spec.coffee](https://github.com/arximboldi/heterarchy/blob/master/spec/heterarchy.spec.coffee)

  [heterarchy]: heterarchy.html
  [spec.heterarchy]: spec/heterarchy.html

Installation
------------

This is a standard [Node.JS](http://nodejs.org) module. One may
install the library with:

> npm install heterarchy
