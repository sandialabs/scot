import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A dropdown menu can contain a menu.
 */
function DropdownMenu(props) {
  var children = props.children,
      className = props.className,
      scrolling = props.scrolling;

  var classes = cx(useKeyOnly(scrolling, 'scrolling'), 'menu transition', className);
  var rest = getUnhandledProps(DropdownMenu, props);
  var ElementType = getElementType(DropdownMenu, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

DropdownMenu.handledProps = ['as', 'children', 'className', 'scrolling'];
DropdownMenu._meta = {
  name: 'DropdownMenu',
  parent: 'Dropdown',
  type: META.TYPES.MODULE
};

process.env.NODE_ENV !== "production" ? DropdownMenu.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A dropdown menu can scroll. */
  scrolling: PropTypes.bool
} : void 0;

export default DropdownMenu;