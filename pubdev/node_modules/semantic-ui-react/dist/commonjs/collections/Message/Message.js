'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Icon = require('../../elements/Icon');

var _Icon2 = _interopRequireDefault(_Icon);

var _MessageContent = require('./MessageContent');

var _MessageContent2 = _interopRequireDefault(_MessageContent);

var _MessageHeader = require('./MessageHeader');

var _MessageHeader2 = _interopRequireDefault(_MessageHeader);

var _MessageList = require('./MessageList');

var _MessageList2 = _interopRequireDefault(_MessageList);

var _MessageItem = require('./MessageItem');

var _MessageItem2 = _interopRequireDefault(_MessageItem);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A message displays information that explains nearby content.
 * @see Form
 */
var Message = function (_Component) {
  (0, _inherits3.default)(Message, _Component);

  function Message() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Message);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Message.__proto__ || Object.getPrototypeOf(Message)).call.apply(_ref, [this].concat(args))), _this), _this.handleDismiss = function (e) {
      var onDismiss = _this.props.onDismiss;


      if (onDismiss) onDismiss(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Message, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          attached = _props.attached,
          children = _props.children,
          className = _props.className,
          color = _props.color,
          compact = _props.compact,
          content = _props.content,
          error = _props.error,
          floating = _props.floating,
          header = _props.header,
          hidden = _props.hidden,
          icon = _props.icon,
          info = _props.info,
          list = _props.list,
          negative = _props.negative,
          onDismiss = _props.onDismiss,
          positive = _props.positive,
          size = _props.size,
          success = _props.success,
          visible = _props.visible,
          warning = _props.warning;


      var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useKeyOnly)(compact, 'compact'), (0, _lib.useKeyOnly)(error, 'error'), (0, _lib.useKeyOnly)(floating, 'floating'), (0, _lib.useKeyOnly)(hidden, 'hidden'), (0, _lib.useKeyOnly)(icon, 'icon'), (0, _lib.useKeyOnly)(info, 'info'), (0, _lib.useKeyOnly)(negative, 'negative'), (0, _lib.useKeyOnly)(positive, 'positive'), (0, _lib.useKeyOnly)(success, 'success'), (0, _lib.useKeyOnly)(visible, 'visible'), (0, _lib.useKeyOnly)(warning, 'warning'), (0, _lib.useKeyOrValueAndKey)(attached, 'attached'), 'message', className);

      var dismissIcon = onDismiss && _react2.default.createElement(_Icon2.default, { name: 'close', onClick: this.handleDismiss });
      var rest = (0, _lib.getUnhandledProps)(Message, this.props);
      var ElementType = (0, _lib.getElementType)(Message, this.props);

      if (!(0, _isNil3.default)(children)) {
        return _react2.default.createElement(
          ElementType,
          (0, _extends3.default)({}, rest, { className: classes }),
          dismissIcon,
          children
        );
      }

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes }),
        dismissIcon,
        _Icon2.default.create(icon),
        (!(0, _isNil3.default)(header) || !(0, _isNil3.default)(content) || !(0, _isNil3.default)(list)) && _react2.default.createElement(
          _MessageContent2.default,
          null,
          _MessageHeader2.default.create(header),
          _MessageList2.default.create(list),
          (0, _lib.createShorthand)('p', function (val) {
            return { children: val };
          }, content)
        )
      );
    }
  }]);
  return Message;
}(_react.Component);

Message._meta = {
  name: 'Message',
  type: _lib.META.TYPES.COLLECTION
};
Message.Content = _MessageContent2.default;
Message.Header = _MessageHeader2.default;
Message.List = _MessageList2.default;
Message.Item = _MessageItem2.default;
exports.default = Message;
process.env.NODE_ENV !== "production" ? Message.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A message can be formatted to attach itself to other content. */
  attached: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['bottom'])]),

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A message can be formatted to be different colors. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** A message can only take up the width of its content. */
  compact: _react.PropTypes.bool,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** A message may be formatted to display a negative message. Same as `negative`. */
  error: _react.PropTypes.bool,

  /** A message can float above content that it is related to. */
  floating: _react.PropTypes.bool,

  /** Shorthand for MessageHeader. */
  header: _lib.customPropTypes.itemShorthand,

  /** A message can be hidden. */
  hidden: _react.PropTypes.bool,

  /** A message can contain an icon. */
  icon: _react.PropTypes.oneOfType([_lib.customPropTypes.itemShorthand, _react.PropTypes.bool]),

  /** A message may be formatted to display information. */
  info: _react.PropTypes.bool,

  /** Array shorthand items for the MessageList. Mutually exclusive with children. */
  list: _lib.customPropTypes.collectionShorthand,

  /** A message may be formatted to display a negative message. Same as `error`. */
  negative: _react.PropTypes.bool,

  /**
   * A message that the user can choose to hide.
   * Called when the user clicks the "x" icon. This also adds the "x" icon.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onDismiss: _react.PropTypes.func,

  /** A message may be formatted to display a positive message.  Same as `success`. */
  positive: _react.PropTypes.bool,

  /** A message may be formatted to display a positive message.  Same as `positive`. */
  success: _react.PropTypes.bool,

  /** A message can have different sizes. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'medium')),

  /** A message can be set to visible to force itself to be shown. */
  visible: _react.PropTypes.bool,

  /** A message may be formatted to display warning messages. */
  warning: _react.PropTypes.bool
} : void 0;
Message.handledProps = ['as', 'attached', 'children', 'className', 'color', 'compact', 'content', 'error', 'floating', 'header', 'hidden', 'icon', 'info', 'list', 'negative', 'onDismiss', 'positive', 'size', 'success', 'visible', 'warning'];