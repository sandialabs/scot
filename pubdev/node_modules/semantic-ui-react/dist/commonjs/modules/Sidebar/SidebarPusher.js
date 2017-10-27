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
 * A pushable sub-component for Sidebar.
 */
function SidebarPusher(props) {
  var className = props.className,
      dimmed = props.dimmed,
      children = props.children;


  var classes = (0, _classnames2.default)('pusher', (0, _lib.useKeyOnly)(dimmed, 'dimmed'), className);
  var rest = (0, _lib.getUnhandledProps)(SidebarPusher, props);
  var ElementType = (0, _lib.getElementType)(SidebarPusher, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

SidebarPusher.handledProps = ['as', 'children', 'className', 'dimmed'];
SidebarPusher._meta = {
  name: 'SidebarPusher',
  type: _lib.META.TYPES.MODULE,
  parent: 'Sidebar'
};

process.env.NODE_ENV !== "production" ? SidebarPusher.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Controls whether or not the dim is displayed. */
  dimmed: _react.PropTypes.bool
} : void 0;

exports.default = SidebarPusher;