import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthand, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import FeedLike from './FeedLike';

/**
 * A feed can contain a meta.
 */
function FeedMeta(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      like = props.like;


  var classes = cx('meta', className);
  var rest = getUnhandledProps(FeedMeta, props);
  var ElementType = getElementType(FeedMeta, props);

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
    createShorthand(FeedLike, function (val) {
      return { content: val };
    }, like),
    content
  );
}

FeedMeta.handledProps = ['as', 'children', 'className', 'content', 'like'];
FeedMeta._meta = {
  name: 'FeedMeta',
  parent: 'Feed',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedMeta.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Shorthand for FeedLike. */
  like: customPropTypes.itemShorthand
} : void 0;

export default FeedMeta;