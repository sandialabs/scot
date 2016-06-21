### This package is deprecated

The bug causing multiple (identical) versions of react is no longer present in React 0.10 with 
Browserify >= 4. 

Rather than use this package, simply use `require('react/addons')` in modules that require addons.

# react-addons

This is an npm package containing *only* the react addons, and not the full react build
itself (although it requires it). This will play much more nicely with browserify
and other build tools than the old `require('react/addons')` style.

This package is a direct copy/paste of the files in `lib/`, with the paths to `/React` changed
to require the base `react` module. If this module gets significantly out of date, it should
be simple to rebuild using the React source.

`react` is a peerDependency of this module, so it won't add extra cruft to your project
and will work nicely with browserify.

## Example Usage

```js

// Previously, you might access React Addons with this path, which actually
// returns the entire React library, with addons accessible via the `addons` property.
// Unfortunately, this can confuse browserify and can add an extra 1MB (unminified)
// to your build.
var React = require('react/addons');

// Now, you can access it this way, separately from React itself, 
// and enjoy the relatively small size (42kb unminified)!
var React = require('react');
var addons = require('react-addons');

// And the addons are available directly on the module, like so:
var classSet = addons.classSet;

// Now, you don't have to worry about changing your require statements
// throughout your app to use `react/addons`!
```
