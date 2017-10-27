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

var _Icon = require('../../elements/Icon');

var _Icon2 = _interopRequireDefault(_Icon);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A feed can contain a like element.
 */
function FeedLike(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      icon = props.icon;


  var classes = (0, _classnames2.default)('like', className);
  var rest = (0, _lib.getUnhandledProps)(FeedLike, props);
  var ElementType = (0, _lib.getElementType)(FeedLike, props);

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
    _Icon2.default.create(icon),
    content
  );
}

FeedLike.handledProps = ['as', 'children', 'className', 'content', 'icon'];
FeedLike._meta = {
  name: 'FeedLike',
  parent: 'Feed',
  type: _lib.META.TYPES.VIEW
};

FeedLike.defaultProps = {
  as: 'a'
};

process.env.NODE_ENV !== "production" ? FeedLike.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** Shorthand for icon. Mutually exclusive with children. */
  icon: _lib.customPropTypes.itemShorthand
} : void 0;

exports.default = FeedLike;