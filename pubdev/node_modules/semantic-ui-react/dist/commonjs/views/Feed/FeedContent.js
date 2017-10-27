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

var _FeedDate = require('./FeedDate');

var _FeedDate2 = _interopRequireDefault(_FeedDate);

var _FeedExtra = require('./FeedExtra');

var _FeedExtra2 = _interopRequireDefault(_FeedExtra);

var _FeedMeta = require('./FeedMeta');

var _FeedMeta2 = _interopRequireDefault(_FeedMeta);

var _FeedSummary = require('./FeedSummary');

var _FeedSummary2 = _interopRequireDefault(_FeedSummary);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function FeedContent(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      extraImages = props.extraImages,
      extraText = props.extraText,
      date = props.date,
      meta = props.meta,
      summary = props.summary;


  var classes = (0, _classnames2.default)('content', className);
  var rest = (0, _lib.getUnhandledProps)(FeedContent, props);
  var ElementType = (0, _lib.getElementType)(FeedContent, props);

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
    (0, _lib.createShorthand)(_FeedDate2.default, function (val) {
      return { content: val };
    }, date),
    (0, _lib.createShorthand)(_FeedSummary2.default, function (val) {
      return { content: val };
    }, summary),
    content,
    (0, _lib.createShorthand)(_FeedExtra2.default, function (val) {
      return { text: true, content: val };
    }, extraText),
    (0, _lib.createShorthand)(_FeedExtra2.default, function (val) {
      return { images: val };
    }, extraImages),
    (0, _lib.createShorthand)(_FeedMeta2.default, function (val) {
      return { content: val };
    }, meta)
  );
}

FeedContent.handledProps = ['as', 'children', 'className', 'content', 'date', 'extraImages', 'extraText', 'meta', 'summary'];
FeedContent._meta = {
  name: 'FeedContent',
  parent: 'Feed',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedContent.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** An event can contain a date. */
  date: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedExtra with images. */
  extraImages: _FeedExtra2.default.propTypes.images,

  /** Shorthand for FeedExtra with text. */
  extraText: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedMeta. */
  meta: _lib.customPropTypes.itemShorthand,

  /** Shorthand for FeedSummary. */
  summary: _lib.customPropTypes.itemShorthand
} : void 0;

exports.default = FeedContent;