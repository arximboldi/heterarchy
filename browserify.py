#!/usr/bin/env python3


import sys

coffee_code = sys.stdin.read()
coffee_code = (
    "    exports = window.heterarchy = {}\n\n" +
    coffee_code
    .replace("require 'underscore'", "_")
)
print(coffee_code)
