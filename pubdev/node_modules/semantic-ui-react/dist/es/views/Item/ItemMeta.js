import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * An item can contain content metadata.
 */
function ItemMeta(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('meta', className);
  var rest = getUnhandledProps(ItemMeta, props);
  var ElementType = getElementType(ItemMeta, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ItemMeta.handledProps = ['as', 'children', 'className', 'content'];
ItemMeta._meta = {
  name: 'ItemMeta',
  parent: 'Item',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? ItemMeta.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

ItemMeta.create = createShorthandFactory(ItemMeta, function (content) {
  return { content: content };
});

export default ItemMeta;