# debug-fabulous

## Install
`npm install --save debug-fabulous`

# Purpose

Wrapper / Extension around [visionmedia's debug](https://github.com/visionmedia/debug) to allow lazy evaluation of debugging via closure handling.

This library essentially wraps two things:

- [lazy-eval](./src/lazy-eval.js): debug closure handling
- [spawn](./src/spawn.js): spawns off existing namespaces for a sub namespace.


## Example:

For usage see the [tests](./test) or the example below.

```js
var debug = require('')();
// force namespace to be enabled otherwise it assumes process.env.DEBUG is setup
// debug.save('namespace');
// debug.enable(debug.load())
debug = debug('namespace'); // debugger in the namespace
debug(function(){return 'ya something to log' + someLargeHarryString;});
debug('small out'); // prints namespace small out
var childDbg = debug.spawn('child'); // debugger in the namespace:child
childDbg('small out'); // prints namespace:child small out
var grandChildDbg = debug.spawn('grandChild'); // debugger in the namespace:child:grandChild
grandChildDbg('small out'); // prints namespace:child:grandChild small out
```
