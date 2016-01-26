react-load-mask
===============

React LoadMask


## Install

```sh
npm i --save react-load-mask
```

## Usage


```jsx
//require the css
require('react-load-mask/index.css')

var LoadMask = require('react-load-mask')

<LoadMask visible={true}/>
<LoadMask visible={true} size={20} />
<LoadMask visible={false} size={120} />
```

The **LoadMask** component will have a `.loadmask` css class
Loadbars will have `.loadbar .loadbar-{index}` css classes

## License

```
MIT
```