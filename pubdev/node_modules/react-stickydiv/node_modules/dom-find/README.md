# Find DOM utils

Utils for finding DOM elements. Used by [react-stickydiv][1]

```js
var util = require('dom-find');

// util.findPos(document.getElementById("element"));
// [0,100]

// util.findPosRelativeToViewport(document.getElementById("element"));
// [50,-200]

```

You can also use this with React

```js
var util = require('dom-find');

// util.findPos(React.findDOMNode());
// [0,100]

// util.findPosRelativeToViewport(React.findDOMNode());
// [50,-200]

```

[1]: https://github.com/svenanders/react-stickydiv
