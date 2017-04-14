'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _map2 = require('lodash/map');

var _map3 = _interopRequireDefault(_map2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A feed can contain an extra content.
 */
function FeedExtra(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      images = props.images,
      text = props.text;


  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(images, 'images'), (0, _lib.useKeyOnly)(content || text, 'text'), 'extra', className);
  var rest = (0, _lib.getUnhandledProps)(FeedExtra, props);
  var ElementType = (0, _lib.getElementType)(FeedExtra, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  // TODO need a "collection factory" to handle creating multiple image elements and their keys
  var imageElements = (0, _map3.default)(images, function (image, index) {
    var key = [index, image].join('-');
    return (0, _lib.createHTMLImage)(image, { key: key });
  });

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    content,
    imageElements
  );
}

FeedExtra.handledProps = ['as', 'children', 'className', 'content', 'images', 'text'];
FeedExtra._meta = {
  name: 'FeedExtra',
  parent: 'Feed',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedExtra.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** An event can contain additional information like a set of images. */
  images: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['text']), _react.PropTypes.oneOfType([_react.PropTypes.bool, _lib.customPropTypes.collectionShorthand])]),

  /** An event can contain additional text information. */
  text: _react.PropTypes.bool
} : void 0;

exports.default = FeedExtra;