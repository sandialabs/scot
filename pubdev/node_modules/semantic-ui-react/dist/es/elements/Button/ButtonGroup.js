import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useValueAndKey, useWidthProp } from '../../lib';

/**
 * Buttons can be grouped.
 */
function ButtonGroup(props) {
  var attached = props.attached,
      basic = props.basic,
      children = props.children,
      className = props.className,
      color = props.color,
      compact = props.compact,
      floated = props.floated,
      fluid = props.fluid,
      icon = props.icon,
      inverted = props.inverted,
      labeled = props.labeled,
      negative = props.negative,
      positive = props.positive,
      primary = props.primary,
      secondary = props.secondary,
      size = props.size,
      toggle = props.toggle,
      vertical = props.vertical,
      widths = props.widths;


  var classes = cx('ui', color, size, useKeyOnly(basic, 'basic'), useKeyOnly(compact, 'compact'), useKeyOnly(fluid, 'fluid'), useKeyOnly(icon, 'icon'), useKeyOnly(inverted, 'inverted'), useKeyOnly(labeled, 'labeled'), useKeyOnly(negative, 'negative'), useKeyOnly(positive, 'positive'), useKeyOnly(primary, 'primary'), useKeyOnly(secondary, 'secondary'), useKeyOnly(toggle, 'toggle'), useKeyOnly(vertical, 'vertical'), useValueAndKey(attached, 'attached'), useValueAndKey(floated, 'floated'), useWidthProp(widths), 'buttons', className);
  var rest = getUnhandledProps(ButtonGroup, props);
  var ElementType = getElementType(ButtonGroup, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

ButtonGroup.handledProps = ['as', 'attached', 'basic', 'children', 'className', 'color', 'compact', 'floated', 'fluid', 'icon', 'inverted', 'labeled', 'negative', 'positive', 'primary', 'secondary', 'size', 'toggle', 'vertical', 'widths'];
ButtonGroup._meta = {
  name: 'ButtonGroup',
  parent: 'Button',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ButtonGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A button can be attached to the top or bottom of other content. */
  attached: PropTypes.oneOf(['left', 'right', 'top', 'bottom']),

  /** Groups can be less pronounced. */
  basic: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Groups can have a shared color. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** Groups can reduce their padding to fit into tighter spaces. */
  compact: PropTypes.bool,

  /** Groups can be aligned to the left or right of its container. */
  floated: PropTypes.oneOf(SUI.FLOATS),

  /** Groups can take the width of their container. */
  fluid: PropTypes.bool,

  /** Groups can be formatted as icons. */
  icon: PropTypes.bool,

  /** Groups can be formatted to appear on dark backgrounds. */
  inverted: PropTypes.bool,

  /** Groups can be formatted as labeled icon buttons. */
  labeled: PropTypes.bool,

  /** Groups can hint towards a negative consequence. */
  negative: PropTypes.bool,

  /** Groups can hint towards a positive consequence. */
  positive: PropTypes.bool,

  /** Groups can be formatted to show different levels of emphasis. */
  primary: PropTypes.bool,

  /** Groups can be formatted to show different levels of emphasis. */
  secondary: PropTypes.bool,

  /** Groups can have different sizes. */
  size: PropTypes.oneOf(SUI.SIZES),

  /** Groups can be formatted to toggle on and off. */
  toggle: PropTypes.bool,

  /** Groups can be formatted to appear vertically. */
  vertical: PropTypes.bool,

  /** Groups can have their widths divided evenly. */
  widths: PropTypes.oneOf(SUI.WIDTHS)
} : void 0;

export default ButtonGroup;