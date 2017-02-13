#!/usr/bin/env node

fs = require('fs');

var coffee_code = fs.readFileSync('/dev/stdin').toString();
coffee_code = "    exports = window.heterarchy = {}\n\n" +
    coffee_code
    .replace("require 'underscore'", "_")
    .replace(/global/g, "window");

console.log(coffee_code);
