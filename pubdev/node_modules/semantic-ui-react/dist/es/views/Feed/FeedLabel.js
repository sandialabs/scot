import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createHTMLImage, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Icon from '../../elements/Icon';

/**
 * An event can contain an image or icon label.
 */
function FeedLabel(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      icon = props.icon,
      image = props.image;


  var classes = cx('label', className);
  var rest = getUnhandledProps(FeedLabel, props);
  var ElementType = getElementType(FeedLabel, props);

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
    content,
    Icon.create(icon),
    createHTMLImage(image)
  );
}

FeedLabel.handledProps = ['as', 'children', 'className', 'content', 'icon', 'image'];
FeedLabel._meta = {
  name: 'FeedLabel',
  parent: 'Feed',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? FeedLabel.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** An event can contain icon label. */
  icon: customPropTypes.itemShorthand,

  /** An event can contain image label. */
  image: customPropTypes.itemShorthand
} : void 0;

export default FeedLabel;