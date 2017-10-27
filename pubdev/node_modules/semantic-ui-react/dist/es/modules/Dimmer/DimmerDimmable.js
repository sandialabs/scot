import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A dimmable sub-component for Dimmer.
 */
function DimmerDimmable(props) {
  var blurring = props.blurring,
      className = props.className,
      children = props.children,
      dimmed = props.dimmed;


  var classes = cx(useKeyOnly(blurring, 'blurring'), useKeyOnly(dimmed, 'dimmed'), 'dimmable', className);
  var rest = getUnhandledProps(DimmerDimmable, props);
  var ElementType = getElementType(DimmerDimmable, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

DimmerDimmable.handledProps = ['as', 'blurring', 'children', 'className', 'dimmed'];
DimmerDimmable._meta = {
  name: 'DimmerDimmable',
  type: META.TYPES.MODULE,
  parent: 'Dimmer'
};

process.env.NODE_ENV !== "production" ? DimmerDimmable.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A dimmable element can blur its contents. */
  blurring: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Controls whether or not the dim is displayed. */
  dimmed: PropTypes.bool
} : void 0;

export default DimmerDimmable;