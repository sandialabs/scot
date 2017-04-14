import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthand, customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';
import CardDescription from './CardDescription';
import CardHeader from './CardHeader';
import CardMeta from './CardMeta';

/**
 * A card can contain blocks of content or extra content meant to be formatted separately from the main content.
 */
function CardContent(props) {
  var children = props.children,
      className = props.className,
      description = props.description,
      extra = props.extra,
      header = props.header,
      meta = props.meta;


  var classes = cx(className, useKeyOnly(extra, 'extra'), 'content');
  var rest = getUnhandledProps(CardContent, props);
  var ElementType = getElementType(CardContent, props);

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
    createShorthand(CardHeader, function (val) {
      return { content: val };
    }, header),
    createShorthand(CardMeta, function (val) {
      return { content: val };
    }, meta),
    createShorthand(CardDescription, function (val) {
      return { content: val };
    }, description)
  );
}

CardContent.handledProps = ['as', 'children', 'className', 'description', 'extra', 'header', 'meta'];
CardContent._meta = {
  name: 'CardContent',
  parent: 'Card',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CardContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for CardDescription. */
  description: customPropTypes.itemShorthand,

  /** A card can contain extra content meant to be formatted separately from the main content. */
  extra: PropTypes.bool,

  /** Shorthand for CardHeader. */
  header: customPropTypes.itemShorthand,

  /** Shorthand for CardMeta. */
  meta: customPropTypes.itemShorthand
} : void 0;

export default CardContent;