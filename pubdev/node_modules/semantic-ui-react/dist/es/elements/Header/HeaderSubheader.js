import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

/**
 * Headers may contain subheaders.
 */
function HeaderSubheader(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('sub header', className);
  var rest = getUnhandledProps(HeaderSubheader, props);
  var ElementType = getElementType(HeaderSubheader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

HeaderSubheader.handledProps = ['as', 'children', 'className', 'content'];
HeaderSubheader._meta = {
  name: 'HeaderSubheader',
  parent: 'Header',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? HeaderSubheader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

HeaderSubheader.create = createShorthandFactory(HeaderSubheader, function (content) {
  return { content: content };
});

export default HeaderSubheader;