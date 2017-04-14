'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A statistic can contain a numeric, icon, image, or text value.
 */
function StatisticValue(props) {
  var children = props.children,
      className = props.className,
      text = props.text,
      value = props.value;


  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(text, 'text'), 'value', className);
  var rest = (0, _lib.getUnhandledProps)(StatisticValue, props);
  var ElementType = (0, _lib.getElementType)(StatisticValue, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? value : children
  );
}

StatisticValue.handledProps = ['as', 'children', 'className', 'text', 'value'];
StatisticValue._meta = {
  name: 'StatisticValue',
  parent: 'Statistic',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? StatisticValue.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Format the value with smaller font size to fit nicely beside number values. */
  text: _react.PropTypes.bool,

  /** Primary content of the StatisticValue. Mutually exclusive with the children prop. */
  value: _lib.customPropTypes.contentShorthand
} : void 0;

exports.default = StatisticValue;