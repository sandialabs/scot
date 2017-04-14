import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';
import _without from 'lodash/without';
import cx from 'classnames';

import React, { Component, PropTypes } from 'react';

import { createShorthand, customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useKeyOrValueAndKey } from '../../lib';
import Icon from '../../elements/Icon';
import MessageContent from './MessageContent';
import MessageHeader from './MessageHeader';
import MessageList from './MessageList';
import MessageItem from './MessageItem';

/**
 * A message displays information that explains nearby content.
 * @see Form
 */

var Message = function (_Component) {
  _inherits(Message, _Component);

  function Message() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Message);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Message.__proto__ || Object.getPrototypeOf(Message)).call.apply(_ref, [this].concat(args))), _this), _this.handleDismiss = function (e) {
      var onDismiss = _this.props.onDismiss;


      if (onDismiss) onDismiss(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Message, [{
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


      var classes = cx('ui', color, size, useKeyOnly(compact, 'compact'), useKeyOnly(error, 'error'), useKeyOnly(floating, 'floating'), useKeyOnly(hidden, 'hidden'), useKeyOnly(icon, 'icon'), useKeyOnly(info, 'info'), useKeyOnly(negative, 'negative'), useKeyOnly(positive, 'positive'), useKeyOnly(success, 'success'), useKeyOnly(visible, 'visible'), useKeyOnly(warning, 'warning'), useKeyOrValueAndKey(attached, 'attached'), 'message', className);

      var dismissIcon = onDismiss && React.createElement(Icon, { name: 'close', onClick: this.handleDismiss });
      var rest = getUnhandledProps(Message, this.props);
      var ElementType = getElementType(Message, this.props);

      if (!_isNil(children)) {
        return React.createElement(
          ElementType,
          _extends({}, rest, { className: classes }),
          dismissIcon,
          children
        );
      }

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes }),
        dismissIcon,
        Icon.create(icon),
        (!_isNil(header) || !_isNil(content) || !_isNil(list)) && React.createElement(
          MessageContent,
          null,
          MessageHeader.create(header),
          MessageList.create(list),
          createShorthand('p', function (val) {
            return { children: val };
          }, content)
        )
      );
    }
  }]);

  return Message;
}(Component);

Message._meta = {
  name: 'Message',
  type: META.TYPES.COLLECTION
};
Message.Content = MessageContent;
Message.Header = MessageHeader;
Message.List = MessageList;
Message.Item = MessageItem;
export default Message;
process.env.NODE_ENV !== "production" ? Message.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A message can be formatted to attach itself to other content. */
  attached: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['bottom'])]),

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A message can be formatted to be different colors. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** A message can only take up the width of its content. */
  compact: PropTypes.bool,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** A message may be formatted to display a negative message. Same as `negative`. */
  error: PropTypes.bool,

  /** A message can float above content that it is related to. */
  floating: PropTypes.bool,

  /** Shorthand for MessageHeader. */
  header: customPropTypes.itemShorthand,

  /** A message can be hidden. */
  hidden: PropTypes.bool,

  /** A message can contain an icon. */
  icon: PropTypes.oneOfType([customPropTypes.itemShorthand, PropTypes.bool]),

  /** A message may be formatted to display information. */
  info: PropTypes.bool,

  /** Array shorthand items for the MessageList. Mutually exclusive with children. */
  list: customPropTypes.collectionShorthand,

  /** A message may be formatted to display a negative message. Same as `error`. */
  negative: PropTypes.bool,

  /**
   * A message that the user can choose to hide.
   * Called when the user clicks the "x" icon. This also adds the "x" icon.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onDismiss: PropTypes.func,

  /** A message may be formatted to display a positive message.  Same as `success`. */
  positive: PropTypes.bool,

  /** A message may be formatted to display a positive message.  Same as `positive`. */
  success: PropTypes.bool,

  /** A message can have different sizes. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'medium')),

  /** A message can be set to visible to force itself to be shown. */
  visible: PropTypes.bool,

  /** A message may be formatted to display warning messages. */
  warning: PropTypes.bool
} : void 0;
Message.handledProps = ['as', 'attached', 'children', 'className', 'color', 'compact', 'content', 'error', 'floating', 'header', 'hidden', 'icon', 'info', 'list', 'negative', 'onDismiss', 'positive', 'size', 'success', 'visible', 'warning'];