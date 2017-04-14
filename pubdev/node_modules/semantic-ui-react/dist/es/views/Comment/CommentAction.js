import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A comment can contain an action.
 */
function CommentAction(props) {
  var active = props.active,
      className = props.className,
      children = props.children;


  var classes = cx(useKeyOnly(active, 'active'), className);
  var rest = getUnhandledProps(CommentAction, props);
  var ElementType = getElementType(CommentAction, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

CommentAction.handledProps = ['active', 'as', 'children', 'className'];
CommentAction._meta = {
  name: 'CommentAction',
  parent: 'Comment',
  type: META.TYPES.VIEW
};

CommentAction.defaultProps = {
  as: 'a'
};

process.env.NODE_ENV !== "production" ? CommentAction.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Style as the currently active action. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default CommentAction;