'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _toConsumableArray2 = require('babel-runtime/helpers/toConsumableArray');

var _toConsumableArray3 = _interopRequireDefault(_toConsumableArray2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _GridColumn = require('./GridColumn');

var _GridColumn2 = _interopRequireDefault(_GridColumn);

var _GridRow = require('./GridRow');

var _GridRow2 = _interopRequireDefault(_GridRow);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A grid is used to harmonize negative space in a layout.
 */
function Grid(props) {
  var celled = props.celled,
      centered = props.centered,
      children = props.children,
      className = props.className,
      columns = props.columns,
      container = props.container,
      divided = props.divided,
      doubling = props.doubling,
      padded = props.padded,
      relaxed = props.relaxed,
      reversed = props.reversed,
      stackable = props.stackable,
      stretched = props.stretched,
      textAlign = props.textAlign,
      verticalAlign = props.verticalAlign;


  var classes = (0, _classnames2.default)('ui', (0, _lib.useKeyOnly)(centered, 'centered'), (0, _lib.useKeyOnly)(container, 'container'), (0, _lib.useKeyOnly)(doubling, 'doubling'), (0, _lib.useKeyOnly)(stackable, 'stackable'), (0, _lib.useKeyOnly)(stretched, 'stretched'), (0, _lib.useKeyOrValueAndKey)(celled, 'celled'), (0, _lib.useKeyOrValueAndKey)(divided, 'divided'), (0, _lib.useKeyOrValueAndKey)(padded, 'padded'), (0, _lib.useKeyOrValueAndKey)(relaxed, 'relaxed'), (0, _lib.useTextAlignProp)(textAlign), (0, _lib.useValueAndKey)(reversed, 'reversed'), (0, _lib.useVerticalAlignProp)(verticalAlign), (0, _lib.useWidthProp)(columns, 'column', true), 'grid', className);
  var rest = (0, _lib.getUnhandledProps)(Grid, props);
  var ElementType = (0, _lib.getElementType)(Grid, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

Grid.handledProps = ['as', 'celled', 'centered', 'children', 'className', 'columns', 'container', 'divided', 'doubling', 'padded', 'relaxed', 'reversed', 'stackable', 'stretched', 'textAlign', 'verticalAlign'];
Grid.Column = _GridColumn2.default;
Grid.Row = _GridRow2.default;

Grid._meta = {
  name: 'Grid',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? Grid.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A grid can have rows divided into cells. */
  celled: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['internally'])]),

  /** A grid can have its columns centered. */
  centered: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Represents column count per row in Grid. */
  columns: _react.PropTypes.oneOf([].concat((0, _toConsumableArray3.default)(_lib.SUI.WIDTHS), ['equal'])),

  /** A grid can be combined with a container to use the available layout and alignment. */
  container: _react.PropTypes.bool,

  /** A grid can have dividers between its columns. */
  divided: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['vertically'])]),

  /** A grid can double its column width on tablet and mobile sizes. */
  doubling: _react.PropTypes.bool,

  /** A grid can preserve its vertical and horizontal gutters on first and last columns. */
  padded: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['horizontally', 'vertically'])]),

  /** A grid can increase its gutters to allow for more negative space. */
  relaxed: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['very'])]),

  /** A grid can specify that its columns should reverse order at different device sizes. */
  reversed: _react.PropTypes.oneOf(['computer', 'computer vertically', 'mobile', 'mobile vertically', 'tablet', 'tablet vertically']),

  /** A grid can have its columns stack on-top of each other after reaching mobile breakpoints. */
  stackable: _react.PropTypes.bool,

  /** A grid can stretch its contents to take up the entire grid height. */
  stretched: _react.PropTypes.bool,

  /** A grid can specify its text alignment. */
  textAlign: _react.PropTypes.oneOf(_lib.SUI.TEXT_ALIGNMENTS),

  /** A grid can specify its vertical alignment to have all its columns vertically centered. */
  verticalAlign: _react.PropTypes.oneOf(_lib.SUI.VERTICAL_ALIGNMENTS)
} : void 0;

exports.default = Grid;