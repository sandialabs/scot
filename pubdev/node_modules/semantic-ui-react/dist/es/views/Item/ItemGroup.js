import _objectWithoutProperties from 'babel-runtime/helpers/objectWithoutProperties';
import _extends from 'babel-runtime/helpers/extends';
import _map from 'lodash/map';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly, useKeyOrValueAndKey } from '../../lib';
import Item from './Item';

/**
 * A group of items.
 */
function ItemGroup(props) {
  var children = props.children,
      className = props.className,
      divided = props.divided,
      items = props.items,
      link = props.link,
      relaxed = props.relaxed;


  var classes = cx('ui', useKeyOnly(divided, 'divided'), useKeyOnly(link, 'link'), useKeyOrValueAndKey(relaxed, 'relaxed'), 'items', className);
  var rest = getUnhandledProps(ItemGroup, props);
  var ElementType = getElementType(ItemGroup, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  var itemsJSX = _map(items, function (item) {
    var childKey = item.childKey,
        itemProps = _objectWithoutProperties(item, ['childKey']);

    var finalKey = childKey || [itemProps.content, itemProps.description, itemProps.header, itemProps.meta].join('-');

    return React.createElement(Item, _extends({}, itemProps, { key: finalKey }));
  });

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    itemsJSX
  );
}

ItemGroup.handledProps = ['as', 'children', 'className', 'divided', 'items', 'link', 'relaxed'];
ItemGroup._meta = {
  name: 'ItemGroup',
  type: META.TYPES.VIEW,
  parent: 'Item'
};

process.env.NODE_ENV !== "production" ? ItemGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Items can be divided to better distinguish between grouped content. */
  divided: PropTypes.bool,

  /** Shorthand array of props for Item. */
  items: customPropTypes.collectionShorthand,

  /** An item can be formatted so that the entire contents link to another page. */
  link: PropTypes.bool,

  /** A group of items can relax its padding to provide more negative space. */
  relaxed: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['very'])])
} : void 0;

export default ItemGroup;