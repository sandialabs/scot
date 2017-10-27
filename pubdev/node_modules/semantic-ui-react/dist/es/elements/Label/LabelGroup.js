import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly } from '../../lib';

/**
 * A label can be grouped.
 */
function LabelGroup(props) {
  var children = props.children,
      circular = props.circular,
      className = props.className,
      color = props.color,
      size = props.size,
      tag = props.tag;


  var classes = cx('ui', color, size, useKeyOnly(circular, 'circular'), useKeyOnly(tag, 'tag'), 'labels', className);
  var rest = getUnhandledProps(LabelGroup, props);
  var ElementType = getElementType(LabelGroup, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

LabelGroup.handledProps = ['as', 'children', 'circular', 'className', 'color', 'size', 'tag'];
LabelGroup._meta = {
  name: 'LabelGroup',
  parent: 'Label',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? LabelGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Labels can share shapes. */
  circular: PropTypes.bool,

  /** Additional classes. */
  className: PropTypes.string,

  /** Label group can share colors together. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** Label group can share sizes together. */
  size: PropTypes.oneOf(SUI.SIZES),

  /** Label group can share tag formatting. */
  tag: PropTypes.bool
} : void 0;

export default LabelGroup;