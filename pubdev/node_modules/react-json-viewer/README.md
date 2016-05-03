# react-json-viewer
React Component for View JSON in beautiful tabular format. See images below.
Note: Images are little old. From version 1.0.7, we show colors too.


[![NPM version][npm-image]][npm-url]
[![npm download][download-image]][download-url]

[npm-image]: http://img.shields.io/npm/v/react-json-viewer.svg?style=flat-square
[npm-url]: https://npmjs.org/package/react-json-viewer
[download-image]: https://img.shields.io/npm/dm/react-json-viewer.svg?style=flat-square
[download-url]: https://npmjs.org/package/react-json-viewer


# Demo

[http://nsisodiya.github.io/react-json-viewer](http://nsisodiya.github.io/react-json-viewer/)

# JSFiddle Example

[http://jsfiddle.net/nsisodiya/61fwqcg5/](http://jsfiddle.net/nsisodiya/61fwqcg5/)

# What

![alt pic](https://raw.githubusercontent.com/nsisodiya/react-json-viewer/master/pic1.png)
![alt pic](https://raw.githubusercontent.com/nsisodiya/react-json-viewer/master/pic2.png)

# Install

[![react-json-viewer](https://nodei.co/npm/react-json-viewer.png?downloads=true)](https://npmjs.org/package/react-json-viewer)

# Use

```
var JSONViewer = require('react-json-viewer');
var todos = [{
 task: "Learn React",
 done: true
},{
 task:"Write Book",
 done: false
}];


<JSONViewer json={todos}></JSONViewer>
```

# Develop
```
npm install
npm run build
```