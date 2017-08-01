import _extends from 'babel-runtime/helpers/extends';
import _without from 'lodash/without';

import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useKeyOrValueAndKey } from '../../lib';

/**
 * A rail is used to show accompanying content outside the boundaries of the main view of a site.
 */
function Rail(props) {
  var attached = props.attached,
      children = props.children,
      className = props.className,
      close = props.close,
      dividing = props.dividing,
      internal = props.internal,
      position = props.position,
      size = props.size;


  var classes = cx('ui', position, size, useKeyOnly(attached, 'attached'), useKeyOnly(dividing, 'dividing'), useKeyOnly(internal, 'internal'), useKeyOrValueAndKey(close, 'close'), 'rail', className);
  var rest = getUnhandledProps(Rail, props);
  var ElementType = getElementType(Rail, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

Rail.handledProps = ['as', 'attached', 'children', 'className', 'close', 'dividing', 'internal', 'position', 'size'];
Rail._meta = {
  name: 'Rail',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Rail.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A rail can appear attached to the main viewport. */
  attached: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A rail can appear closer to the main viewport. */
  close: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['very'])]),

  /** A rail can create a division between itself and a container. */
  dividing: PropTypes.bool,

  /** A rail can attach itself to the inside of a container. */
  internal: PropTypes.bool,

  /** A rail can be presented on the left or right side of a container. */
  position: PropTypes.oneOf(SUI.FLOATS).isRequired,

  /** A rail can have different sizes. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'medium'))
} : void 0;

export default Rail;