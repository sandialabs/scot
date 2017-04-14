import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A pushable sub-component for Sidebar.
 */
function SidebarPusher(props) {
  var className = props.className,
      dimmed = props.dimmed,
      children = props.children;


  var classes = cx('pusher', useKeyOnly(dimmed, 'dimmed'), className);
  var rest = getUnhandledProps(SidebarPusher, props);
  var ElementType = getElementType(SidebarPusher, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

SidebarPusher.handledProps = ['as', 'children', 'className', 'dimmed'];
SidebarPusher._meta = {
  name: 'SidebarPusher',
  type: META.TYPES.MODULE,
  parent: 'Sidebar'
};

process.env.NODE_ENV !== "production" ? SidebarPusher.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Controls whether or not the dim is displayed. */
  dimmed: PropTypes.bool
} : void 0;

export default SidebarPusher;