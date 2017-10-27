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
 * A comment can contain an author.
 */
function CommentAuthor(props) {
  var className = props.className,
      children = props.children;

  var classes = (0, _classnames2.default)('author', className);
  var rest = (0, _lib.getUnhandledProps)(CommentAuthor, props);
  var ElementType = (0, _lib.getElementType)(CommentAuthor, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

CommentAuthor.handledProps = ['as', 'children', 'className'];
CommentAuthor._meta = {
  name: 'CommentAuthor',
  parent: 'Comment',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentAuthor.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string
} : void 0;

exports.default = CommentAuthor;