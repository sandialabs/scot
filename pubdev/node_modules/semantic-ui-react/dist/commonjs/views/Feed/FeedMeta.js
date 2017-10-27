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

var _FeedLike = require('./FeedLike');

var _FeedLike2 = _interopRequireDefault(_FeedLike);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A feed can contain a meta.
 */
function FeedMeta(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      like = props.like;


  var classes = (0, _classnames2.default)('meta', className);
  var rest = (0, _lib.getUnhandledProps)(FeedMeta, props);
  var ElementType = (0, _lib.getElementType)(FeedMeta, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _lib.createShorthand)(_FeedLike2.default, function (val) {
      return { content: val };
    }, like),
    content
  );
}

FeedMeta.handledProps = ['as', 'children', 'className', 'content', 'like'];
FeedMeta._meta = {
  name: 'FeedMeta',
  parent: 'Feed',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedMeta.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** Shorthand for FeedLike. */
  like: _lib.customPropTypes.itemShorthand
} : void 0;

exports.default = FeedMeta;