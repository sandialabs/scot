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

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A label can be grouped.
 */
function LabelGroup(props) {
  var children = props.children,
      circular = props.circular,
      className = props.className,
      color = props.color,
      size = props.size,
      tag = props.tag;


  var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useKeyOnly)(circular, 'circular'), (0, _lib.useKeyOnly)(tag, 'tag'), 'labels', className);
  var rest = (0, _lib.getUnhandledProps)(LabelGroup, props);
  var ElementType = (0, _lib.getElementType)(LabelGroup, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

LabelGroup.handledProps = ['as', 'children', 'circular', 'className', 'color', 'size', 'tag'];
LabelGroup._meta = {
  name: 'LabelGroup',
  parent: 'Label',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? LabelGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Labels can share shapes. */
  circular: _react.PropTypes.bool,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Label group can share colors together. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** Label group can share sizes together. */
  size: _react.PropTypes.oneOf(_lib.SUI.SIZES),

  /** Label group can share tag formatting. */
  tag: _react.PropTypes.bool
} : void 0;

exports.default = LabelGroup;