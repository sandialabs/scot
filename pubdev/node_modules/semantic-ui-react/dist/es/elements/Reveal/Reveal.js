import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';
import RevealContent from './RevealContent';

/**
 * A reveal displays additional content in place of previous content when activated.
 */
function Reveal(props) {
  var active = props.active,
      animated = props.animated,
      children = props.children,
      className = props.className,
      disabled = props.disabled,
      instant = props.instant;


  var classes = cx('ui', animated, useKeyOnly(active, 'active'), useKeyOnly(disabled, 'disabled'), useKeyOnly(instant, 'instant'), 'reveal', className);
  var rest = getUnhandledProps(Reveal, props);
  var ElementType = getElementType(Reveal, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

Reveal.handledProps = ['active', 'animated', 'as', 'children', 'className', 'disabled', 'instant'];
Reveal._meta = {
  name: 'Reveal',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Reveal.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** An active reveal displays its hidden content. */
  active: PropTypes.bool,

  /** An animation name that will be applied to Reveal. */
  animated: PropTypes.oneOf(['fade', 'small fade', 'move', 'move right', 'move up', 'move down', 'rotate', 'rotate left']),

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A disabled reveal will not animate when hovered. */
  disabled: PropTypes.bool,

  /** An element can show its content without delay. */
  instant: PropTypes.bool
} : void 0;

Reveal.Content = RevealContent;

export default Reveal;