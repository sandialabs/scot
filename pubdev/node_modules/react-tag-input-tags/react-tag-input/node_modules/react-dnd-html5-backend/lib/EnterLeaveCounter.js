'use strict';

exports.__esModule = true;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

var _lodashArrayUnion = require('lodash/array/union');

var _lodashArrayUnion2 = _interopRequireDefault(_lodashArrayUnion);

var _lodashArrayWithout = require('lodash/array/without');

var _lodashArrayWithout2 = _interopRequireDefault(_lodashArrayWithout);

var EnterLeaveCounter = (function () {
  function EnterLeaveCounter() {
    _classCallCheck(this, EnterLeaveCounter);

    this.entered = [];
  }

  EnterLeaveCounter.prototype.enter = function enter(enteringNode) {
    var previousLength = this.entered.length;

    this.entered = _lodashArrayUnion2['default'](this.entered.filter(function (node) {
      return document.documentElement.contains(node) && (!node.contains || node.contains(enteringNode));
    }), [enteringNode]);

    return previousLength === 0 && this.entered.length > 0;
  };

  EnterLeaveCounter.prototype.leave = function leave(leavingNode) {
    var previousLength = this.entered.length;

    this.entered = _lodashArrayWithout2['default'](this.entered.filter(function (node) {
      return document.documentElement.contains(node);
    }), leavingNode);

    return previousLength > 0 && this.entered.length === 0;
  };

  EnterLeaveCounter.prototype.reset = function reset() {
    this.entered = [];
  };

  return EnterLeaveCounter;
})();

exports['default'] = EnterLeaveCounter;
module.exports = exports['default'];