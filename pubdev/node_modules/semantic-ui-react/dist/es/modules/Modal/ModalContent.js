import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A modal can contain content.
 */
function ModalContent(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      image = props.image;


  var classes = cx(className, useKeyOnly(image, 'image'), 'content');
  var rest = getUnhandledProps(ModalContent, props);
  var ElementType = getElementType(ModalContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ModalContent.handledProps = ['as', 'children', 'className', 'content', 'image'];
ModalContent._meta = {
  name: 'ModalContent',
  type: META.TYPES.MODULE,
  parent: 'Modal'
};

process.env.NODE_ENV !== "production" ? ModalContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** A modal can contain image content. */
  image: PropTypes.bool
} : void 0;

ModalContent.create = createShorthandFactory(ModalContent, function (content) {
  return { content: content };
});

export default ModalContent;