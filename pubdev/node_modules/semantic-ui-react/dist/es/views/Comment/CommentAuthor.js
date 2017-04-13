import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A comment can contain an author.
 */
function CommentAuthor(props) {
  var className = props.className,
      children = props.children;

  var classes = cx('author', className);
  var rest = getUnhandledProps(CommentAuthor, props);
  var ElementType = getElementType(CommentAuthor, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

CommentAuthor.handledProps = ['as', 'children', 'className'];
CommentAuthor._meta = {
  name: 'CommentAuthor',
  parent: 'Comment',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentAuthor.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default CommentAuthor;