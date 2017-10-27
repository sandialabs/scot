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
 * A table can have a header.
 */
function TableHeader(props) {
  var children = props.children,
      className = props.className,
      fullWidth = props.fullWidth;

  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(fullWidth, 'full-width'), className);
  var rest = (0, _lib.getUnhandledProps)(TableHeader, props);
  var ElementType = (0, _lib.getElementType)(TableHeader, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

TableHeader.handledProps = ['as', 'children', 'className', 'fullWidth'];
TableHeader._meta = {
  name: 'TableHeader',
  type: _lib.META.TYPES.COLLECTION,
  parent: 'Table'
};

TableHeader.defaultProps = {
  as: 'thead'
};

process.env.NODE_ENV !== "production" ? TableHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A definition table can have a full width header or footer, filling in the gap left by the first column. */
  fullWidth: _react.PropTypes.bool
} : void 0;

exports.default = TableHeader;