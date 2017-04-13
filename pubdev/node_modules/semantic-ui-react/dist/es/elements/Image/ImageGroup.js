import _extends from 'babel-runtime/helpers/extends';
import React, { PropTypes } from 'react';
import cx from 'classnames';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI } from '../../lib';

/**
 * A group of images.
 */
function ImageGroup(props) {
  var children = props.children,
      className = props.className,
      size = props.size;

  var classes = cx('ui', size, className, 'images');
  var rest = getUnhandledProps(ImageGroup, props);
  var ElementType = getElementType(ImageGroup, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

ImageGroup.handledProps = ['as', 'children', 'className', 'size'];
ImageGroup._meta = {
  name: 'ImageGroup',
  parent: 'Image',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ImageGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A group of images can be formatted to have the same size. */
  size: PropTypes.oneOf(SUI.SIZES)
} : void 0;

export default ImageGroup;