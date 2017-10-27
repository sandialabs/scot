import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Icon from '../../elements/Icon';

/**
 * A feed can contain a like element.
 */
function FeedLike(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      icon = props.icon;


  var classes = cx('like', className);
  var rest = getUnhandledProps(FeedLike, props);
  var ElementType = getElementType(FeedLike, props);

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
    Icon.create(icon),
    content
  );
}

FeedLike.handledProps = ['as', 'children', 'className', 'content', 'icon'];
FeedLike._meta = {
  name: 'FeedLike',
  parent: 'Feed',
  type: META.TYPES.VIEW
};

FeedLike.defaultProps = {
  as: 'a'
};

process.env.NODE_ENV !== "production" ? FeedLike.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Shorthand for icon. Mutually exclusive with children. */
  icon: customPropTypes.itemShorthand
} : void 0;

export default FeedLike;