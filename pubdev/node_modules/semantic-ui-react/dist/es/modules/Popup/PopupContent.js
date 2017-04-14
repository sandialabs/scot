import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A PopupContent displays the content body of a Popover.
 */
export default function PopupContent(props) {
  var children = props.children,
      className = props.className;

  var classes = cx('content', className);
  var rest = getUnhandledProps(PopupContent, props);
  var ElementType = getElementType(PopupContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

PopupContent.handledProps = ['as', 'children', 'className'];
process.env.NODE_ENV !== "production" ? PopupContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** The content of the Popup */
  children: PropTypes.node,

  /** Classes to add to the Popup content className. */
  className: PropTypes.string
} : void 0;

PopupContent._meta = {
  name: 'PopupContent',
  type: META.TYPES.MODULE,
  parent: 'Popup'
};

PopupContent.create = createShorthandFactory(PopupContent, function (children) {
  return { children: children };
});