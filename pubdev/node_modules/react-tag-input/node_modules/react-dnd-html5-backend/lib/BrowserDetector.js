'use strict';

exports.__esModule = true;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _lodashFunctionMemoize = require('lodash/function/memoize');

var _lodashFunctionMemoize2 = _interopRequireDefault(_lodashFunctionMemoize);

var isFirefox = _lodashFunctionMemoize2['default'](function () {
  return (/firefox/i.test(navigator.userAgent)
  );
});

exports.isFirefox = isFirefox;
var isSafari = _lodashFunctionMemoize2['default'](function () {
  return Boolean(window.safari);
});
exports.isSafari = isSafari;