import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A menu can contain a sub menu.
 */
function MenuMenu(props) {
  var children = props.children,
      className = props.className,
      position = props.position;


  var classes = cx(position, 'menu', className);
  var rest = getUnhandledProps(MenuMenu, props);
  var ElementType = getElementType(MenuMenu, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

MenuMenu.handledProps = ['as', 'children', 'className', 'position'];
MenuMenu._meta = {
  name: 'MenuMenu',
  type: META.TYPES.COLLECTION,
  parent: 'Menu'
};

process.env.NODE_ENV !== "production" ? MenuMenu.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A sub menu can take right position. */
  position: PropTypes.oneOf(['right'])
} : void 0;

export default MenuMenu;