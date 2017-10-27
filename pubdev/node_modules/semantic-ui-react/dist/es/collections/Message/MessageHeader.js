import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A message can contain a header.
 */
function MessageHeader(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('header', className);
  var rest = getUnhandledProps(MessageHeader, props);
  var ElementType = getElementType(MessageHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

MessageHeader.handledProps = ['as', 'children', 'className', 'content'];
MessageHeader._meta = {
  name: 'MessageHeader',
  parent: 'Message',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? MessageHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.itemShorthand
} : void 0;

MessageHeader.create = createShorthandFactory(MessageHeader, function (val) {
  return { content: val };
});

export default MessageHeader;