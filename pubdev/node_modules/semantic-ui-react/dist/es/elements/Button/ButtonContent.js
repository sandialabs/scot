import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * Used in some Button types, such as `animated`.
 */
function ButtonContent(props) {
  var children = props.children,
      className = props.className,
      hidden = props.hidden,
      visible = props.visible;

  var classes = cx(useKeyOnly(visible, 'visible'), useKeyOnly(hidden, 'hidden'), 'content', className);
  var rest = getUnhandledProps(ButtonContent, props);
  var ElementType = getElementType(ButtonContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

ButtonContent.handledProps = ['as', 'children', 'className', 'hidden', 'visible'];
ButtonContent._meta = {
  name: 'ButtonContent',
  parent: 'Button',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ButtonContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Initially hidden, visible on hover. */
  hidden: PropTypes.bool,

  /** Initially visible, hidden on hover. */
  visible: PropTypes.bool
} : void 0;

export default ButtonContent;