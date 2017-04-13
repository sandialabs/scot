'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _TableCell = require('./TableCell');

var _TableCell2 = _interopRequireDefault(_TableCell);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A table can have a header cell.
 */
function TableHeaderCell(props) {
  var as = props.as,
      className = props.className,
      sorted = props.sorted;

  var classes = (0, _classnames2.default)((0, _lib.useValueAndKey)(sorted, 'sorted'), className);
  var rest = (0, _lib.getUnhandledProps)(TableHeaderCell, props);

  return _react2.default.createElement(_TableCell2.default, (0, _extends3.default)({}, rest, { as: as, className: classes }));
}

TableHeaderCell.handledProps = ['as', 'className', 'sorted'];
TableHeaderCell._meta = {
  name: 'TableHeaderCell',
  type: _lib.META.TYPES.COLLECTION,
  parent: 'Table'
};

process.env.NODE_ENV !== "production" ? TableHeaderCell.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A header cell can be sorted in ascending or descending order. */
  sorted: _react.PropTypes.oneOf(['ascending', 'descending'])
} : void 0;

TableHeaderCell.defaultProps = {
  as: 'th'
};

exports.default = TableHeaderCell;