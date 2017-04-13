'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _map2 = require('lodash/map');

var _map3 = _interopRequireDefault(_map2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _TableCell = require('./TableCell');

var _TableCell2 = _interopRequireDefault(_TableCell);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A table can have rows.
 */
function TableRow(props) {
  var active = props.active,
      cellAs = props.cellAs,
      cells = props.cells,
      children = props.children,
      className = props.className,
      disabled = props.disabled,
      error = props.error,
      negative = props.negative,
      positive = props.positive,
      textAlign = props.textAlign,
      verticalAlign = props.verticalAlign,
      warning = props.warning;


  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(active, 'active'), (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(error, 'error'), (0, _lib.useKeyOnly)(negative, 'negative'), (0, _lib.useKeyOnly)(positive, 'positive'), (0, _lib.useKeyOnly)(warning, 'warning'), (0, _lib.useTextAlignProp)(textAlign), (0, _lib.useVerticalAlignProp)(verticalAlign), className);
  var rest = (0, _lib.getUnhandledProps)(TableRow, props);
  var ElementType = (0, _lib.getElementType)(TableRow, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _map3.default)(cells, function (cell) {
      return _TableCell2.default.create(cell, { as: cellAs });
    })
  );
}

TableRow.handledProps = ['active', 'as', 'cellAs', 'cells', 'children', 'className', 'disabled', 'error', 'negative', 'positive', 'textAlign', 'verticalAlign', 'warning'];
TableRow._meta = {
  name: 'TableRow',
  type: _lib.META.TYPES.COLLECTION,
  parent: 'Table'
};

TableRow.defaultProps = {
  as: 'tr',
  cellAs: 'td'
};

process.env.NODE_ENV !== "production" ? TableRow.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A row can be active or selected by a user. */
  active: _react.PropTypes.bool,

  /** An element type to render as (string or function). */
  cellAs: _lib.customPropTypes.as,

  /** Shorthand array of props for TableCell. */
  cells: _lib.customPropTypes.collectionShorthand,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A row can be disabled. */
  disabled: _react.PropTypes.bool,

  /** A row may call attention to an error or a negative value. */
  error: _react.PropTypes.bool,

  /** A row may let a user know whether a value is bad. */
  negative: _react.PropTypes.bool,

  /** A row may let a user know whether a value is good. */
  positive: _react.PropTypes.bool,

  /** A table row can adjust its text alignment. */
  textAlign: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.TEXT_ALIGNMENTS, 'justified')),

  /** A table row can adjust its vertical alignment. */
  verticalAlign: _react.PropTypes.oneOf(_lib.SUI.VERTICAL_ALIGNMENTS),

  /** A row may warn a user. */
  warning: _react.PropTypes.bool
} : void 0;

TableRow.create = (0, _lib.createShorthandFactory)(TableRow, function (cells) {
  return { cells: cells };
}, true);

exports.default = TableRow;