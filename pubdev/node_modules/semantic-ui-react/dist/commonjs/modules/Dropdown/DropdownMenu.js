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
 * A dropdown menu can contain a menu.
 */
function DropdownMenu(props) {
  var children = props.children,
      className = props.className,
      scrolling = props.scrolling;

  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(scrolling, 'scrolling'), 'menu transition', className);
  var rest = (0, _lib.getUnhandledProps)(DropdownMenu, props);
  var ElementType = (0, _lib.getElementType)(DropdownMenu, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

DropdownMenu.handledProps = ['as', 'children', 'className', 'scrolling'];
DropdownMenu._meta = {
  name: 'DropdownMenu',
  parent: 'Dropdown',
  type: _lib.META.TYPES.MODULE
};

process.env.NODE_ENV !== "production" ? DropdownMenu.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A dropdown menu can scroll. */
  scrolling: _react.PropTypes.bool
} : void 0;

exports.default = DropdownMenu;