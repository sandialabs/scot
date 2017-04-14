import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getUnhandledProps, META, useValueAndKey } from '../../lib';
import TableCell from './TableCell';

/**
 * A table can have a header cell.
 */
function TableHeaderCell(props) {
  var as = props.as,
      className = props.className,
      sorted = props.sorted;

  var classes = cx(useValueAndKey(sorted, 'sorted'), className);
  var rest = getUnhandledProps(TableHeaderCell, props);

  return React.createElement(TableCell, _extends({}, rest, { as: as, className: classes }));
}

TableHeaderCell.handledProps = ['as', 'className', 'sorted'];
TableHeaderCell._meta = {
  name: 'TableHeaderCell',
  type: META.TYPES.COLLECTION,
  parent: 'Table'
};

process.env.NODE_ENV !== "production" ? TableHeaderCell.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Additional classes. */
  className: PropTypes.string,

  /** A header cell can be sorted in ascending or descending order. */
  sorted: PropTypes.oneOf(['ascending', 'descending'])
} : void 0;

TableHeaderCell.defaultProps = {
  as: 'th'
};

export default TableHeaderCell;