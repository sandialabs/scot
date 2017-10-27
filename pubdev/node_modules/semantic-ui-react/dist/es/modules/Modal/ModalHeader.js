import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A modal can have a header.
 */
function ModalHeader(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx(className, 'header');
  var rest = getUnhandledProps(ModalHeader, props);
  var ElementType = getElementType(ModalHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ModalHeader.handledProps = ['as', 'children', 'className', 'content'];
ModalHeader._meta = {
  name: 'ModalHeader',
  type: META.TYPES.MODULE,
  parent: 'Modal'
};

process.env.NODE_ENV !== "production" ? ModalHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

ModalHeader.create = createShorthandFactory(ModalHeader, function (content) {
  return { content: content };
});

export default ModalHeader;