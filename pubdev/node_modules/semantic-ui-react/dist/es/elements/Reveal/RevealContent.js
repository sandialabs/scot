import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A content sub-component for the Reveal.
 */
function RevealContent(props) {
  var children = props.children,
      className = props.className,
      hidden = props.hidden,
      visible = props.visible;


  var classes = cx('ui', useKeyOnly(hidden, 'hidden'), useKeyOnly(visible, 'visible'), 'content', className);
  var rest = getUnhandledProps(RevealContent, props);
  var ElementType = getElementType(RevealContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

RevealContent.handledProps = ['as', 'children', 'className', 'hidden', 'visible'];
RevealContent._meta = {
  name: 'RevealContent',
  parent: 'Reveal',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? RevealContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A reveal may contain content that is visible before interaction. */
  hidden: PropTypes.bool,

  /** A reveal may contain content that is hidden before user interaction. */
  visible: PropTypes.bool
} : void 0;

export default RevealContent;