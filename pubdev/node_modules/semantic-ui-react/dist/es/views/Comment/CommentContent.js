import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A comment can contain content.
 */
function CommentContent(props) {
  var className = props.className,
      children = props.children;

  var classes = cx(className, 'content');
  var rest = getUnhandledProps(CommentContent, props);
  var ElementType = getElementType(CommentContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

CommentContent.handledProps = ['as', 'children', 'className'];
CommentContent._meta = {
  name: 'CommentContent',
  parent: 'Comment',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default CommentContent;