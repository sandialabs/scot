import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A card can contain content metadata.
 */
function CardMeta(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx(className, 'meta');
  var rest = getUnhandledProps(CardMeta, props);
  var ElementType = getElementType(CardMeta, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

CardMeta.handledProps = ['as', 'children', 'className', 'content'];
CardMeta._meta = {
  name: 'CardMeta',
  parent: 'Card',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CardMeta.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

export default CardMeta;