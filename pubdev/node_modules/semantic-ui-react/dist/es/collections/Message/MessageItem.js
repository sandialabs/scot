import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A message list can contain an item.
 */
function MessageItem(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('content', className);
  var rest = getUnhandledProps(MessageItem, props);
  var ElementType = getElementType(MessageItem, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

MessageItem.handledProps = ['as', 'children', 'className', 'content'];
MessageItem._meta = {
  name: 'MessageItem',
  parent: 'Message',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? MessageItem.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.itemShorthand
} : void 0;

MessageItem.defaultProps = {
  as: 'li'
};

MessageItem.create = createShorthandFactory(MessageItem, function (content) {
  return { content: content };
}, true);

export default MessageItem;