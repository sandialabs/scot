import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * An item can contain extra content meant to be formatted separately from the main content.
 */
function ItemExtra(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('extra', className);
  var rest = getUnhandledProps(ItemExtra, props);
  var ElementType = getElementType(ItemExtra, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ItemExtra.handledProps = ['as', 'children', 'className', 'content'];
ItemExtra._meta = {
  name: 'ItemExtra',
  parent: 'Item',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? ItemExtra.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

ItemExtra.create = createShorthandFactory(ItemExtra, function (content) {
  return { content: content };
});

export default ItemExtra;