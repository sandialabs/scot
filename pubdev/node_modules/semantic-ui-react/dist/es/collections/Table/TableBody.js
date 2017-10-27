import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

function TableBody(props) {
  var children = props.children,
      className = props.className;

  var classes = cx(className);
  var rest = getUnhandledProps(TableBody, props);
  var ElementType = getElementType(TableBody, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

TableBody.handledProps = ['as', 'children', 'className'];
TableBody._meta = {
  name: 'TableBody',
  type: META.TYPES.COLLECTION,
  parent: 'Table'
};

TableBody.defaultProps = {
  as: 'tbody'
};

process.env.NODE_ENV !== "production" ? TableBody.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default TableBody;