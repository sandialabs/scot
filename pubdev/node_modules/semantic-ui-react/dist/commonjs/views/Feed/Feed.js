'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _map2 = require('lodash/map');

var _map3 = _interopRequireDefault(_map2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _FeedContent = require('./FeedContent');

var _FeedContent2 = _interopRequireDefault(_FeedContent);

var _FeedDate = require('./FeedDate');

var _FeedDate2 = _interopRequireDefault(_FeedDate);

var _FeedEvent = require('./FeedEvent');

var _FeedEvent2 = _interopRequireDefault(_FeedEvent);

var _FeedExtra = require('./FeedExtra');

var _FeedExtra2 = _interopRequireDefault(_FeedExtra);

var _FeedLabel = require('./FeedLabel');

var _FeedLabel2 = _interopRequireDefault(_FeedLabel);

var _FeedLike = require('./FeedLike');

var _FeedLike2 = _interopRequireDefault(_FeedLike);

var _FeedMeta = require('./FeedMeta');

var _FeedMeta2 = _interopRequireDefault(_FeedMeta);

var _FeedSummary = require('./FeedSummary');

var _FeedSummary2 = _interopRequireDefault(_FeedSummary);

var _FeedUser = require('./FeedUser');

var _FeedUser2 = _interopRequireDefault(_FeedUser);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A feed presents user activity chronologically.
 */
function Feed(props) {
  var children = props.children,
      className = props.className,
      events = props.events,
      size = props.size;


  var classes = (0, _classnames2.default)('ui', size, 'feed', className);
  var rest = (0, _lib.getUnhandledProps)(Feed, props);
  var ElementType = (0, _lib.getElementType)(Feed, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  var eventElements = (0, _map3.default)(events, function (eventProps) {
    var childKey = eventProps.childKey,
        date = eventProps.date,
        meta = eventProps.meta,
        summary = eventProps.summary,
        eventData = (0, _objectWithoutProperties3.default)(eventProps, ['childKey', 'date', 'meta', 'summary']);

    var finalKey = childKey || [date, meta, summary].join('-');

    return _react2.default.createElement(_FeedEvent2.default, (0, _extends3.default)({
      date: date,
      key: finalKey,
      meta: meta,
      summary: summary
    }, eventData));
  });

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    eventElements
  );
}

Feed.handledProps = ['as', 'children', 'className', 'events', 'size'];
Feed._meta = {
  name: 'Feed',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? Feed.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand array of props for FeedEvent. */
  events: _lib.customPropTypes.collectionShorthand,

  /** A feed can have different sizes. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'mini', 'tiny', 'medium', 'big', 'huge', 'massive'))
} : void 0;

Feed.Content = _FeedContent2.default;
Feed.Date = _FeedDate2.default;
Feed.Event = _FeedEvent2.default;
Feed.Extra = _FeedExtra2.default;
Feed.Label = _FeedLabel2.default;
Feed.Like = _FeedLike2.default;
Feed.Meta = _FeedMeta2.default;
Feed.Summary = _FeedSummary2.default;
Feed.User = _FeedUser2.default;

exports.default = Feed;