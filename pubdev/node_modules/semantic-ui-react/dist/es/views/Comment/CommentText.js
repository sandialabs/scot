import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A comment can contain text.
 */
function CommentText(props) {
  var className = props.className,
      children = props.children;

  var classes = cx(className, 'text');
  var rest = getUnhandledProps(CommentText, props);
  var ElementType = getElementType(CommentText, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

CommentText.handledProps = ['as', 'children', 'className'];
CommentText._meta = {
  name: 'CommentText',
  parent: 'Comment',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentText.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default CommentText;