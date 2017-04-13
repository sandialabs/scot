import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

function StepDescription(props) {
  var children = props.children,
      className = props.className,
      description = props.description;

  var classes = cx('description', className);
  var rest = getUnhandledProps(StepDescription, props);
  var ElementType = getElementType(StepDescription, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? description : children
  );
}

StepDescription.handledProps = ['as', 'children', 'className', 'description'];
StepDescription._meta = {
  name: 'StepDescription',
  parent: 'Step',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? StepDescription.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Additional classes. */
  className: PropTypes.string,

  /** Primary content. */
  children: PropTypes.node,

  /** Shorthand for primary content. */
  description: customPropTypes.contentShorthand
} : void 0;

export default StepDescription;