import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthand, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import StepDescription from './StepDescription';
import StepTitle from './StepTitle';

/**
 * A step can contain a content.
 */
function StepContent(props) {
  var children = props.children,
      className = props.className,
      description = props.description,
      title = props.title;

  var classes = cx('content', className);
  var rest = getUnhandledProps(StepContent, props);
  var ElementType = getElementType(StepContent, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    createShorthand(StepTitle, function (val) {
      return { title: val };
    }, title),
    createShorthand(StepDescription, function (val) {
      return { description: val };
    }, description)
  );
}

StepContent.handledProps = ['as', 'children', 'className', 'description', 'title'];
StepContent._meta = {
  name: 'StepContent',
  parent: 'Step',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? StepContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Additional classes. */
  className: PropTypes.string,

  /** Primary content. */
  children: PropTypes.node,

  /** Shorthand for StepDescription. */
  description: customPropTypes.itemShorthand,

  /** Shorthand for StepTitle. */
  title: customPropTypes.itemShorthand
} : void 0;

export default StepContent;