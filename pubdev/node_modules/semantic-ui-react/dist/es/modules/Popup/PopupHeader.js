import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A PopupHeader displays a header in a Popover.
 */
export default function PopupHeader(props) {
  var children = props.children,
      className = props.className;

  var classes = cx('header', className);
  var rest = getUnhandledProps(PopupHeader, props);
  var ElementType = getElementType(PopupHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

PopupHeader.handledProps = ['as', 'children', 'className'];
process.env.NODE_ENV !== "production" ? PopupHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

PopupHeader._meta = {
  name: 'PopupHeader',
  type: META.TYPES.MODULE,
  parent: 'Popup'
};

PopupHeader.create = createShorthandFactory(PopupHeader, function (children) {
  return { children: children };
});