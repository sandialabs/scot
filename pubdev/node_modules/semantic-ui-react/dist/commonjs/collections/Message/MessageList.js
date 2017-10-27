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

var _MessageItem = require('./MessageItem');

var _MessageItem2 = _interopRequireDefault(_MessageItem);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A message can contain a list of items.
 */
function MessageList(props) {
  var children = props.children,
      className = props.className,
      items = props.items;

  var classes = (0, _classnames2.default)('list', className);
  var rest = (0, _lib.getUnhandledProps)(MessageList, props);
  var ElementType = (0, _lib.getElementType)(MessageList, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? (0, _map3.default)(items, _MessageItem2.default.create) : children
  );
}

MessageList.handledProps = ['as', 'children', 'className', 'items'];
MessageList._meta = {
  name: 'MessageList',
  parent: 'Message',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? MessageList.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand Message.Items. */
  items: _lib.customPropTypes.collectionShorthand
} : void 0;

MessageList.defaultProps = {
  as: 'ul'
};

MessageList.create = (0, _lib.createShorthandFactory)(MessageList, function (val) {
  return { items: val };
});

exports.default = MessageList;