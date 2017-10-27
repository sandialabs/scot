import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * An item can contain a header.
 */
function ItemHeader(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('header', className);
  var rest = getUnhandledProps(ItemHeader, props);
  var ElementType = getElementType(ItemHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ItemHeader.handledProps = ['as', 'children', 'className', 'content'];
ItemHeader._meta = {
  name: 'ItemHeader',
  parent: 'Item',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? ItemHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

ItemHeader.create = createShorthandFactory(ItemHeader, function (content) {
  return { content: content };
});

export default ItemHeader;