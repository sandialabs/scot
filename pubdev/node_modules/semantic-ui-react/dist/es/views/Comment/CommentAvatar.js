import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { createHTMLImage, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A comment can contain an image or avatar.
 */
function CommentAvatar(props) {
  var className = props.className,
      src = props.src;

  var classes = cx('avatar', className);
  var rest = getUnhandledProps(CommentAvatar, props);
  var ElementType = getElementType(CommentAvatar, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    createHTMLImage(src)
  );
}

CommentAvatar.handledProps = ['as', 'className', 'src'];
CommentAvatar._meta = {
  name: 'CommentAvatar',
  parent: 'Comment',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? CommentAvatar.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Additional classes. */
  className: PropTypes.string,

  /** Specifies the URL of the image. */
  src: PropTypes.string
} : void 0;

export default CommentAvatar;