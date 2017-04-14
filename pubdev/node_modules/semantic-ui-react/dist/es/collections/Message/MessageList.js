import _extends from 'babel-runtime/helpers/extends';
import _map from 'lodash/map';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import MessageItem from './MessageItem';

/**
 * A message can contain a list of items.
 */
function MessageList(props) {
  var children = props.children,
      className = props.className,
      items = props.items;

  var classes = cx('list', className);
  var rest = getUnhandledProps(MessageList, props);
  var ElementType = getElementType(MessageList, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? _map(items, MessageItem.create) : children
  );
}

MessageList.handledProps = ['as', 'children', 'className', 'items'];
MessageList._meta = {
  name: 'MessageList',
  parent: 'Message',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? MessageList.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand Message.Items. */
  items: customPropTypes.collectionShorthand
} : void 0;

MessageList.defaultProps = {
  as: 'ul'
};

MessageList.create = createShorthandFactory(MessageList, function (val) {
  return { items: val };
});

export default MessageList;