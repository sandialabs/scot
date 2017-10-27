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
 * A comment can contain metadata about the comment, an arbitrary amount of metadata may be defined.
 */
function CommentMetadata(props) {
  var className = props.className,
      children = props.children;

  var classes = (0, _classnames2.default)('metadata', className);
  var rest = (0, _lib.getUnhandledProps)(CommentMetadata, props);
  var ElementType = (0, _lib.getElementType)(CommentMetadata, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

CommentMetadata.handledProps = ['as', 'children', 'className'];
CommentMetadata._meta = {
  name: 'CommentMetadata',
  parent: 'Comment',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentMetadata.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string
} : void 0;

exports.default = CommentMetadata;