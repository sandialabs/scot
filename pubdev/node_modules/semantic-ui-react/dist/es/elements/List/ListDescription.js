import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * A list item can contain a description.
 */
function ListDescription(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx(className, 'description');
  var rest = getUnhandledProps(ListDescription, props);
  var ElementType = getElementType(ListDescription, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

ListDescription.handledProps = ['as', 'children', 'className', 'content'];
ListDescription._meta = {
  name: 'ListDescription',
  parent: 'List',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ListDescription.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

ListDescription.create = createShorthandFactory(ListDescription, function (content) {
  return { content: content };
});

export default ListDescription;