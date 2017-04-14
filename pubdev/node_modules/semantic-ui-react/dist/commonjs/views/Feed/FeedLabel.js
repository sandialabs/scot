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
 * An event can contain an image or icon label.
 */
function FeedLabel(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      icon = props.icon,
      image = props.image;


  var classes = (0, _classnames2.default)('label', className);
  var rest = (0, _lib.getUnhandledProps)(FeedLabel, props);
  var ElementType = (0, _lib.getElementType)(FeedLabel, props);

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
    content,
    _Icon2.default.create(icon),
    (0, _lib.createHTMLImage)(image)
  );
}

FeedLabel.handledProps = ['as', 'children', 'className', 'content', 'icon', 'image'];
FeedLabel._meta = {
  name: 'FeedLabel',
  parent: 'Feed',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedLabel.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** An event can contain icon label. */
  icon: _lib.customPropTypes.itemShorthand,

  /** An event can contain image label. */
  image: _lib.customPropTypes.itemShorthand
} : void 0;

exports.default = FeedLabel;