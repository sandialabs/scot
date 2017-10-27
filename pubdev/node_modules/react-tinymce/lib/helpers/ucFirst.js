"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = ucFirst;

function ucFirst(str) {
  return str[0].toUpperCase() + str.substring(1);
}

module.exports = exports["default"];