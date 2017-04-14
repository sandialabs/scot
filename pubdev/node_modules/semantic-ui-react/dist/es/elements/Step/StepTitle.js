import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A step can contain a title.
 */
function StepTitle(props) {
  var children = props.children,
      className = props.className,
      title = props.title;

  var classes = cx('title', className);
  var rest = getUnhandledProps(StepTitle, props);
  var ElementType = getElementType(StepTitle, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? title : children
  );
}

StepTitle.handledProps = ['as', 'children', 'className', 'title'];
StepTitle._meta = {
  name: 'StepTitle',
  parent: 'Step',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? StepTitle.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Additional classes. */
  className: PropTypes.string,

  /** Primary content. */
  children: PropTypes.node,

  /** Shorthand for primary content. */
  title: customPropTypes.contentShorthand
} : void 0;

export default StepTitle;