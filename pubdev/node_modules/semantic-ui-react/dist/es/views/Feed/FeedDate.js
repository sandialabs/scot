import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * An event or an event summary can contain a date.
 */
function FeedDate(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('date', className);
  var rest = getUnhandledProps(FeedDate, props);
  var ElementType = getElementType(FeedDate, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

FeedDate.handledProps = ['as', 'children', 'className', 'content'];
FeedDate._meta = {
  name: 'FeedDate',
  parent: 'Feed',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedDate.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

export default FeedDate;