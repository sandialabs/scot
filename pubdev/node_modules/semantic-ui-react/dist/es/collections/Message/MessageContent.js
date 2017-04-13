import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A message can contain a content.
 */
function MessageContent(props) {
  var children = props.children,
      className = props.className;

  var classes = cx('content', className);
  var rest = getUnhandledProps(MessageContent, props);
  var ElementType = getElementType(MessageContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

MessageContent.handledProps = ['as', 'children', 'className'];
MessageContent._meta = {
  name: 'MessageContent',
  parent: 'Message',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? MessageContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default MessageContent;