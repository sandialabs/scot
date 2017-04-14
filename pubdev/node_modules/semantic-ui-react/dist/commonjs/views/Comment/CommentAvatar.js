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
 * A comment can contain an image or avatar.
 */
function CommentAvatar(props) {
  var className = props.className,
      src = props.src;

  var classes = (0, _classnames2.default)('avatar', className);
  var rest = (0, _lib.getUnhandledProps)(CommentAvatar, props);
  var ElementType = (0, _lib.getElementType)(CommentAvatar, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _lib.createHTMLImage)(src)
  );
}

CommentAvatar.handledProps = ['as', 'className', 'src'];
CommentAvatar._meta = {
  name: 'CommentAvatar',
  parent: 'Comment',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentAvatar.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Specifies the URL of the image. */
  src: _react.PropTypes.string
} : void 0;

exports.default = CommentAvatar;