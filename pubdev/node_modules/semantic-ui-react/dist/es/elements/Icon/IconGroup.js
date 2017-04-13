import _extends from 'babel-runtime/helpers/extends';
import _without from 'lodash/without';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI } from '../../lib';

/**
 * Several icons can be used together as a group.
 */
function IconGroup(props) {
  var children = props.children,
      className = props.className,
      size = props.size;

  var classes = cx(size, 'icons', className);
  var rest = getUnhandledProps(IconGroup, props);
  var ElementType = getElementType(IconGroup, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

IconGroup.handledProps = ['as', 'children', 'className', 'size'];
IconGroup._meta = {
  name: 'IconGroup',
  parent: 'Icon',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? IconGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Size of the icon group. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'medium'))
} : void 0;

IconGroup.defaultProps = {
  as: 'i'
};

export default IconGroup;