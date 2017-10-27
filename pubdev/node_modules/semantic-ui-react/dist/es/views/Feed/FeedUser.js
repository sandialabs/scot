import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A feed can contain a user element.
 */
function FeedUser(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('user', className);
  var rest = getUnhandledProps(FeedUser, props);
  var ElementType = getElementType(FeedUser, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

FeedUser.handledProps = ['as', 'children', 'className', 'content'];
FeedUser._meta = {
  name: 'FeedUser',
  parent: 'Feed',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedUser.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

FeedUser.defaultProps = {
  as: 'a'
};

export default FeedUser;