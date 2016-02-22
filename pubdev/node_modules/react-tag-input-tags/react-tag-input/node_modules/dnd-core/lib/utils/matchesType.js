'use strict';

exports.__esModule = true;
exports['default'] = matchesType;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _lodashLangIsArray = require('lodash/lang/isArray');

var _lodashLangIsArray2 = _interopRequireDefault(_lodashLangIsArray);

function matchesType(targetType, draggedItemType) {
  if (_lodashLangIsArray2['default'](targetType)) {
    return targetType.some(function (t) {
      return t === draggedItemType;
    });
  } else {
    return targetType === draggedItemType;
  }
}

module.exports = exports['default'];