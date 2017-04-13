import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A menu item may include a header or may itself be a header.
 */
function MenuHeader(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('header', className);
  var rest = getUnhandledProps(MenuHeader, props);
  var ElementType = getElementType(MenuHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

MenuHeader.handledProps = ['as', 'children', 'className', 'content'];
MenuHeader._meta = {
  name: 'MenuHeader',
  type: META.TYPES.COLLECTION,
  parent: 'Menu'
};

process.env.NODE_ENV !== "production" ? MenuHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

export default MenuHeader;