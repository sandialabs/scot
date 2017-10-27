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

var _FeedContent = require('./FeedContent');

var _FeedContent2 = _interopRequireDefault(_FeedContent);

var _FeedLabel = require('./FeedLabel');

var _FeedLabel2 = _interopRequireDefault(_FeedLabel);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A feed contains an event.
 */
function FeedEvent(props) {
  var content = props.content,
      children = props.children,
      className = props.className,
      date = props.date,
      extraImages = props.extraImages,
      extraText = props.extraText,
      image = props.image,
      icon = props.icon,
      meta = props.meta,
      summary = props.summary;


  var classes = (0, _classnames2.default)('event', className);
  var rest = (0, _lib.getUnhandledProps)(FeedEvent, props);
  var ElementType = (0, _lib.getElementType)(FeedEvent, props);

  var hasContentProp = content || date || extraImages || extraText || meta || summary;
  var contentProps = { content: content, date: date, extraImages: extraImages, extraText: extraText, meta: meta, summary: summary };

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _lib.createShorthand)(_FeedLabel2.default, function (val) {
      return { icon: val };
    }, icon),
    (0, _lib.createShorthand)(_FeedLabel2.default, function (val) {
      return { image: val };
    }, image),
    hasContentProp && _react2.default.createElement(_FeedContent2.default, contentProps),
    children
  );
}

FeedEvent.handledProps = ['as', 'children', 'className', 'content', 'date', 'extraImages', 'extraText', 'icon', 'image', 'meta', 'summary'];
FeedEvent._meta = {
  name: 'FeedEvent',
  parent: 'Feed',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedEvent.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for FeedContent. */
  content: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedDate. */
  date: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedExtra with images. */
  extraImages: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedExtra with content. */
  extraText: _lib.customPropTypes.itemShorthand,

  /** An event can contain icon label. */
  icon: _lib.customPropTypes.itemShorthand,

  /** An event can contain image label. */
  image: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedMeta. */
  meta: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedSummary. */
  summary: _lib.customPropTypes.itemShorthand
} : void 0;

exports.default = FeedEvent;