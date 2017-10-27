import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A list item can contain a header.
 */
function ListHeader(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('header', className);
  var rest = getUnhandledProps(ListHeader, props);
  var ElementType = getElementType(ListHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ListHeader.handledProps = ['as', 'children', 'className', 'content'];
ListHeader._meta = {
  name: 'ListHeader',
  parent: 'List',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ListHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

ListHeader.create = createShorthandFactory(ListHeader, function (content) {
  return { content: content };
});

export default ListHeader;