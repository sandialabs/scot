import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import ItemContent from './ItemContent';
import ItemDescription from './ItemDescription';
import ItemExtra from './ItemExtra';
import ItemGroup from './ItemGroup';
import ItemHeader from './ItemHeader';
import ItemImage from './ItemImage';
import ItemMeta from './ItemMeta';

/**
 * An item view presents large collections of site content for display.
 */
function Item(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      description = props.description,
      extra = props.extra,
      header = props.header,
      image = props.image,
      meta = props.meta;


  var classes = cx('item', className);
  var rest = getUnhandledProps(Item, props);
  var ElementType = getElementType(Item, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    ItemImage.create(image),
    React.createElement(ItemContent, {
      content: content,
      description: description,
      extra: extra,
      header: header,
      meta: meta
    })
  );
}

Item.handledProps = ['as', 'children', 'className', 'content', 'description', 'extra', 'header', 'image', 'meta'];
Item._meta = {
  name: 'Item',
  type: META.TYPES.VIEW
};

Item.Content = ItemContent;
Item.Description = ItemDescription;
Item.Extra = ItemExtra;
Item.Group = ItemGroup;
Item.Header = ItemHeader;
Item.Image = ItemImage;
Item.Meta = ItemMeta;

process.env.NODE_ENV !== "production" ? Item.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for ItemContent component. */
  content: customPropTypes.contentShorthand,

  /** Shorthand for ItemDescription component. */
  description: customPropTypes.itemShorthand,

  /** Shorthand for ItemExtra component. */
  extra: customPropTypes.itemShorthand,

  /** Shorthand for ItemImage component. */
  image: customPropTypes.itemShorthand,

  /** Shorthand for ItemHeader component. */
  header: customPropTypes.itemShorthand,

  /** Shorthand for ItemMeta component. */
  meta: customPropTypes.itemShorthand
} : void 0;

export default Item;