'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.numberToWordMap = undefined;

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

exports.numberToWord = numberToWord;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var numberToWordMap = exports.numberToWordMap = {
  1: 'one',
  2: 'two',
  3: 'three',
  4: 'four',
  5: 'five',
  6: 'six',
  7: 'seven',
  8: 'eight',
  9: 'nine',
  10: 'ten',
  11: 'eleven',
  12: 'twelve',
  13: 'thirteen',
  14: 'fourteen',
  15: 'fifteen',
  16: 'sixteen'
};

/**
 * Return the number word for numbers 1-16.
 * Returns strings or numbers as is if there is no corresponding word.
 * Returns an empty string if value is not a string or number.
 * @param {string|number} value The value to convert to a word.
 * @returns {string}
 */
function numberToWord(value) {
  var type = typeof value === 'undefined' ? 'undefined' : (0, _typeof3.default)(value);
  if (type === 'string' || type === 'number') {
    return numberToWordMap[value] || value;
  }

  return '';
}