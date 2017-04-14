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
 * Used in some Button types, such as `animated`.
 */
function ButtonContent(props) {
  var children = props.children,
      className = props.className,
      hidden = props.hidden,
      visible = props.visible;

  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(visible, 'visible'), (0, _lib.useKeyOnly)(hidden, 'hidden'), 'content', className);
  var rest = (0, _lib.getUnhandledProps)(ButtonContent, props);
  var ElementType = (0, _lib.getElementType)(ButtonContent, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

ButtonContent.handledProps = ['as', 'children', 'className', 'hidden', 'visible'];
ButtonContent._meta = {
  name: 'ButtonContent',
  parent: 'Button',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ButtonContent.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Initially hidden, visible on hover. */
  hidden: _react.PropTypes.bool,

  /** Initially visible, hidden on hover. */
  visible: _react.PropTypes.bool
} : void 0;

exports.default = ButtonContent;