/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "/";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 656);
/******/ })
/************************************************************************/
/******/ ({

/***/ 656:
/***/ (function(module, exports, __webpack_require__) {

module.exports = __webpack_require__(657);


/***/ }),

/***/ 657:
/***/ (function(module, __webpack_exports__) {

"use strict";
throw new Error("Module build failed: SyntaxError: Unexpected token (10:16)\n\n\u001b[0m \u001b[90m  8 | \u001b[39mlet customHistory   \u001b[33m=\u001b[39m require( \u001b[32m'history'\u001b[39m )\u001b[33m.\u001b[39mcreateBrowserHistory\u001b[33m;\u001b[39m\n \u001b[90m  9 | \u001b[39m\n\u001b[31m\u001b[1m>\u001b[22m\u001b[39m\u001b[90m 10 | \u001b[39m\u001b[33mReactDOM\u001b[39m\u001b[33m.\u001b[39mrender(\u001b[33m<\u001b[39m\u001b[33mHashRouter\u001b[39m history\u001b[33m=\u001b[39m{customHistory()}\u001b[33m>\u001b[39m\n \u001b[90m    | \u001b[39m                \u001b[31m\u001b[1m^\u001b[22m\u001b[39m\n \u001b[90m 11 | \u001b[39m    \u001b[33m<\u001b[39m\u001b[33mSwitch\u001b[39m\u001b[33m>\u001b[39m\n \u001b[90m 12 | \u001b[39m        \u001b[33m<\u001b[39m\u001b[33mRoute\u001b[39m exact path \u001b[33m=\u001b[39m \u001b[32m'/'\u001b[39m component \u001b[33m=\u001b[39m {\u001b[33mApp\u001b[39m} \u001b[33m/\u001b[39m\u001b[33m>\u001b[39m\n \u001b[90m 13 | \u001b[39m        \u001b[33m<\u001b[39m\u001b[33mRoute\u001b[39m exact path \u001b[33m=\u001b[39m \u001b[32m'/:value'\u001b[39m component \u001b[33m=\u001b[39m {\u001b[33mApp\u001b[39m} \u001b[33m/\u001b[39m\u001b[33m>\u001b[39m\u001b[0m\n");

/***/ })

/******/ });
//# sourceMappingURL=main.227bd2db.js.map