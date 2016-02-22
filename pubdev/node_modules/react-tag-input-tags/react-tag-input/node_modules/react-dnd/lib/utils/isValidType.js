'use strict';

exports.__esModule = true;
exports['default'] = isValidType;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _lodashLangIsArray = require('lodash/lang/isArray');

var _lodashLangIsArray2 = _interopRequireDefault(_lodashLangIsArray);

function isValidType(type, allowArray) {
       return typeof type === 'string' || typeof type === 'symbol' || allowArray && _lodashLangIsArray2['default'](type) && type.every(function (t) {
              return isValidType(t, false);
       });
}

module.exports = exports['default'];