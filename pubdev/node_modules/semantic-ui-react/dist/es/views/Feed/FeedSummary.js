import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthand, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import FeedDate from './FeedDate';
import FeedUser from './FeedUser';

/**
 * A feed can contain a summary.
 */
function FeedSummary(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      date = props.date,
      user = props.user;


  var classes = cx('summary', className);
  var rest = getUnhandledProps(FeedSummary, props);
  var ElementType = getElementType(FeedSummary, props);

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
    createShorthand(FeedUser, function (val) {
      return { content: val };
    }, user),
    content,
    createShorthand(FeedDate, function (val) {
      return { content: val };
    }, date)
  );
}

FeedSummary.handledProps = ['as', 'children', 'className', 'content', 'date', 'user'];
FeedSummary._meta = {
  name: 'FeedSummary',
  parent: 'Feed',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedSummary.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Shorthand for FeedDate. */
  date: customPropTypes.itemShorthand,

  /** Shorthand for FeedUser. */
  user: customPropTypes.itemShorthand
} : void 0;

export default FeedSummary;