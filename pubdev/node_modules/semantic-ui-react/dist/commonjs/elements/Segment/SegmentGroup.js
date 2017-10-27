'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A group of segments can be formatted to appear together.
 */
function SegmentGroup(props) {
  var children = props.children,
      className = props.className,
      compact = props.compact,
      horizontal = props.horizontal,
      piled = props.piled,
      raised = props.raised,
      size = props.size,
      stacked = props.stacked;


  var classes = (0, _classnames2.default)('ui', size, (0, _lib.useKeyOnly)(compact, 'compact'), (0, _lib.useKeyOnly)(horizontal, 'horizontal'), (0, _lib.useKeyOnly)(piled, 'piled'), (0, _lib.useKeyOnly)(raised, 'raised'), (0, _lib.useKeyOnly)(stacked, 'stacked'), 'segments', className);
  var rest = (0, _lib.getUnhandledProps)(SegmentGroup, props);
  var ElementType = (0, _lib.getElementType)(SegmentGroup, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

SegmentGroup.handledProps = ['as', 'children', 'className', 'compact', 'horizontal', 'piled', 'raised', 'size', 'stacked'];
SegmentGroup._meta = {
  name: 'SegmentGroup',
  parent: 'Segment',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? SegmentGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A segment may take up only as much space as is necessary. */
  compact: _react.PropTypes.bool,

  /** Formats content to be aligned horizontally. */
  horizontal: _react.PropTypes.bool,

  /** Formatted to look like a pile of pages. */
  piled: _react.PropTypes.bool,

  /** A segment group may be formatted to raise above the page. */
  raised: _react.PropTypes.bool,

  /** A segment group can have different sizes. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'medium')),

  /** Formatted to show it contains multiple pages. */
  stacked: _react.PropTypes.bool
} : void 0;

exports.default = SegmentGroup;