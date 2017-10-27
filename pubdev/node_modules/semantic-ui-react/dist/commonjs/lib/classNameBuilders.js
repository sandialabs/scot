'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.useWidthProp = exports.useVerticalAlignProp = exports.useTextAlignProp = exports.useOnlyProp = exports.useKeyOrValueAndKey = exports.useValueAndKey = exports.useKeyOnly = undefined;

var _typeof2 = require('babel-runtime/helpers/typeof');

var _typeof3 = _interopRequireDefault(_typeof2);

var _numberToWord = require('./numberToWord');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/*
 * There are 3 prop patterns used to build up the className for a component.
 * Each utility here is meant for use in a classnames() argument.
 *
 * There is no util for valueOnly() because it would simply return val.
 * Use the prop value inline instead.
 *   <Label size='big' />
 *   <div class="ui big label"></div>
 */

/**
 * Props where only the prop key is used in the className.
 * @param {*} val A props value
 * @param {string} key A props key
 *
 * @example
 * <Label tag />
 * <div class="ui tag label"></div>
 */
var useKeyOnly = exports.useKeyOnly = function useKeyOnly(val, key) {
  return val && key;
};

/**
 * Props that require both a key and value to create a className.
 * @param {*} val A props value
 * @param {string} key A props key
 *
 * @example
 * <Label corner='left' />
 * <div class="ui left corner label"></div>
 */
var useValueAndKey = exports.useValueAndKey = function useValueAndKey(val, key) {
  return val && val !== true && val + ' ' + key;
};

/**
 * Props whose key will be used in className, or value and key.
 * @param {*} val A props value
 * @param {string} key A props key
 *
 * @example Key Only
 * <Label pointing />
 * <div class="ui pointing label"></div>
 *
 * @example Key and Value
 * <Label pointing='left' />
 * <div class="ui left pointing label"></div>
 */
var useKeyOrValueAndKey = exports.useKeyOrValueAndKey = function useKeyOrValueAndKey(val, key) {
  return val && (val === true ? key : val + ' ' + key);
};

//
// Prop to className exceptions
//

/**
 * The "only" prop implements control of visibility classes for Grid subcomponents.
 *
 * @param {*} val The value of the "only" prop
 *
 * @example
 * <Grid.Row only='mobile' />
 * <Grid.Row only='mobile tablet' />
 * <div class="mobile only row"></div>
 * <div class="mobile only tablet only row"></div>
 */
var useOnlyProp = exports.useOnlyProp = function useOnlyProp(val) {
  if (!val || val === true) return null;

  return val.replace('large screen', 'large-screen').split(' ').map(function (prop) {
    return prop.replace('-', ' ') + ' only';
  }).join(' ');
};

/**
 * The "textAlign" prop follows the useValueAndKey except when the value is "justified'.
 * In this case, only the class "justified" is used, ignoring the "aligned" class.
 * @param {*} val The value of the "textAlign" prop
 *
 * @example
 * <Container textAlign='justified' />
 * <div class="ui justified container"></div>
 *
 * @example
 * <Container textAlign='left' />
 * <div class="ui left aligned container"></div>
 */
var useTextAlignProp = exports.useTextAlignProp = function useTextAlignProp(val) {
  return val === 'justified' ? 'justified' : useValueAndKey(val, 'aligned');
};

/**
 * The "verticalAlign" prop follows the useValueAndKey.
 *
 * @param {*} val The value of the "verticalAlign" prop
 *
 * @example
 * <Grid verticalAlign='middle' />
 * <div class="ui middle aligned grid"></div>
 */
var useVerticalAlignProp = exports.useVerticalAlignProp = function useVerticalAlignProp(val) {
  return useValueAndKey(val, 'aligned');
};

/**
 * Create "X", "X wide" and "equal width" classNames.
 * "X" is a numberToWord value and "wide" is configurable.
 * @param {*} val The prop value
 * @param {string} [widthClass=''] The class
 * @param {boolean} [canEqual=false] Flag that indicates possibility of "equal" value
 *
 * @example
 * <Grid columns='equal' />
 * <div class="ui equal width grid"></div>
 *
 * <Form widths='equal' />
 * <div class="ui equal width form"></div>
 *
 * <FieldGroup widths='equal' />
 * <div class="equal width fields"></div>
 *
 * @example
 * <Grid columns={4} />
 * <div class="ui four column grid"></div>
 */
var useWidthProp = exports.useWidthProp = function useWidthProp(val) {
  var widthClass = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : '';
  var canEqual = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

  if (canEqual && val === 'equal') {
    return 'equal width';
  }
  var valType = typeof val === 'undefined' ? 'undefined' : (0, _typeof3.default)(val);
  if ((valType === 'string' || valType === 'number') && widthClass) {
    return (0, _numberToWord.numberToWord)(val) + ' ' + widthClass;
  }
  return (0, _numberToWord.numberToWord)(val);
};