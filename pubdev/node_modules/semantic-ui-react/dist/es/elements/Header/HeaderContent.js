import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * Header content wraps the main content when there is an adjacent Icon or Image.
 */
function HeaderContent(props) {
  var children = props.children,
      className = props.className;

  var classes = cx('content', className);
  var rest = getUnhandledProps(HeaderContent, props);
  var ElementType = getElementType(HeaderContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

HeaderContent.handledProps = ['as', 'children', 'className'];
HeaderContent._meta = {
  name: 'HeaderContent',
  parent: 'Header',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? HeaderContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default HeaderContent;