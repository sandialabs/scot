import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A table can have a header.
 */
function TableHeader(props) {
  var children = props.children,
      className = props.className,
      fullWidth = props.fullWidth;

  var classes = cx(useKeyOnly(fullWidth, 'full-width'), className);
  var rest = getUnhandledProps(TableHeader, props);
  var ElementType = getElementType(TableHeader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

TableHeader.handledProps = ['as', 'children', 'className', 'fullWidth'];
TableHeader._meta = {
  name: 'TableHeader',
  type: META.TYPES.COLLECTION,
  parent: 'Table'
};

TableHeader.defaultProps = {
  as: 'thead'
};

process.env.NODE_ENV !== "production" ? TableHeader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A definition table can have a full width header or footer, filling in the gap left by the first column. */
  fullWidth: PropTypes.bool
} : void 0;

export default TableHeader;