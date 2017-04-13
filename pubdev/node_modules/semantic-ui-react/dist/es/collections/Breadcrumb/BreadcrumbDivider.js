import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getUnhandledProps, getElementType, META } from '../../lib';
import Icon from '../../elements/Icon';

/**
 * A divider sub-component for Breadcrumb component.
 */
function BreadcrumbDivider(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      icon = props.icon;


  var classes = cx('divider', className);
  var rest = getUnhandledProps(BreadcrumbDivider, props);
  var ElementType = getElementType(BreadcrumbDivider, props);

  var iconElement = Icon.create(icon, _extends({}, rest, { className: classes }));
  if (iconElement) return iconElement;

  var breadcrumbContent = content;
  if (_isNil(content)) breadcrumbContent = _isNil(children) ? '/' : children;

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    breadcrumbContent
  );
}

BreadcrumbDivider.handledProps = ['as', 'children', 'className', 'content', 'icon'];
BreadcrumbDivider._meta = {
  name: 'BreadcrumbDivider',
  type: META.TYPES.COLLECTION,
  parent: 'Breadcrumb'
};

process.env.NODE_ENV !== "production" ? BreadcrumbDivider.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Render as an `Icon` component with `divider` class instead of a `div`. */
  icon: customPropTypes.itemShorthand
} : void 0;

BreadcrumbDivider.create = createShorthandFactory(BreadcrumbDivider, function (icon) {
  return { icon: icon };
});

export default BreadcrumbDivider;