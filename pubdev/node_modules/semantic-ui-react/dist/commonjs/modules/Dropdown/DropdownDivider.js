'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A dropdown menu can contain dividers to separate related content.
 */
function DropdownDivider(props) {
  var className = props.className;

  var classes = (0, _classnames2.default)('divider', className);
  var rest = (0, _lib.getUnhandledProps)(DropdownDivider, props);
  var ElementType = (0, _lib.getElementType)(DropdownDivider, props);

  return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { className: classes }));
}

DropdownDivider.handledProps = ['as', 'className'];
DropdownDivider._meta = {
  name: 'DropdownDivider',
  parent: 'Dropdown',
  type: _lib.META.TYPES.MODULE
};

process.env.NODE_ENV !== "production" ? DropdownDivider.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Additional classes. */
  className: _react.PropTypes.string
} : void 0;

exports.default = DropdownDivider;