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
 * An item can contain extra content meant to be formatted separately from the main content.
 */
function ItemExtra(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = (0, _classnames2.default)('extra', className);
  var rest = (0, _lib.getUnhandledProps)(ItemExtra, props);
  var ElementType = (0, _lib.getElementType)(ItemExtra, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? content : children
  );
}

ItemExtra.handledProps = ['as', 'children', 'className', 'content'];
ItemExtra._meta = {
  name: 'ItemExtra',
  parent: 'Item',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? ItemExtra.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand
} : void 0;

ItemExtra.create = (0, _lib.createShorthandFactory)(ItemExtra, function (content) {
  return { content: content };
});

exports.default = ItemExtra;