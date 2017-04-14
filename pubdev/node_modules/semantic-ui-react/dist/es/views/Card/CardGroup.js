import _extends from 'babel-runtime/helpers/extends';
import _map from 'lodash/map';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useWidthProp } from '../../lib';
import Card from './Card';

/**
 * A group of cards.
 */
function CardGroup(props) {
  var children = props.children,
      className = props.className,
      doubling = props.doubling,
      items = props.items,
      itemsPerRow = props.itemsPerRow,
      stackable = props.stackable;


  var classes = cx('ui', useKeyOnly(doubling, 'doubling'), useKeyOnly(stackable, 'stackable'), useWidthProp(itemsPerRow), className, 'cards');
  var rest = getUnhandledProps(CardGroup, props);
  var ElementType = getElementType(CardGroup, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  var content = _map(items, function (item) {
    var key = item.key || [item.header, item.description].join('-');
    return React.createElement(Card, _extends({ key: key }, item));
  });

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    content
  );
}

CardGroup.handledProps = ['as', 'children', 'className', 'doubling', 'items', 'itemsPerRow', 'stackable'];
CardGroup._meta = {
  name: 'CardGroup',
  parent: 'Card',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CardGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A group of cards can double its column width for mobile. */
  doubling: PropTypes.bool,

  /** Shorthand array of props for Card. */
  items: customPropTypes.collectionShorthand,

  /** A group of cards can set how many cards should exist in a row. */
  itemsPerRow: PropTypes.oneOf(SUI.WIDTHS),

  /** A group of cards can automatically stack rows to a single columns on mobile devices. */
  stackable: PropTypes.bool
} : void 0;

export default CardGroup;