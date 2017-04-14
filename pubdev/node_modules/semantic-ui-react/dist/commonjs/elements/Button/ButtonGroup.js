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
 * Buttons can be grouped.
 */
function ButtonGroup(props) {
  var attached = props.attached,
      basic = props.basic,
      children = props.children,
      className = props.className,
      color = props.color,
      compact = props.compact,
      floated = props.floated,
      fluid = props.fluid,
      icon = props.icon,
      inverted = props.inverted,
      labeled = props.labeled,
      negative = props.negative,
      positive = props.positive,
      primary = props.primary,
      secondary = props.secondary,
      size = props.size,
      toggle = props.toggle,
      vertical = props.vertical,
      widths = props.widths;


  var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useKeyOnly)(basic, 'basic'), (0, _lib.useKeyOnly)(compact, 'compact'), (0, _lib.useKeyOnly)(fluid, 'fluid'), (0, _lib.useKeyOnly)(icon, 'icon'), (0, _lib.useKeyOnly)(inverted, 'inverted'), (0, _lib.useKeyOnly)(labeled, 'labeled'), (0, _lib.useKeyOnly)(negative, 'negative'), (0, _lib.useKeyOnly)(positive, 'positive'), (0, _lib.useKeyOnly)(primary, 'primary'), (0, _lib.useKeyOnly)(secondary, 'secondary'), (0, _lib.useKeyOnly)(toggle, 'toggle'), (0, _lib.useKeyOnly)(vertical, 'vertical'), (0, _lib.useValueAndKey)(attached, 'attached'), (0, _lib.useValueAndKey)(floated, 'floated'), (0, _lib.useWidthProp)(widths), 'buttons', className);
  var rest = (0, _lib.getUnhandledProps)(ButtonGroup, props);
  var ElementType = (0, _lib.getElementType)(ButtonGroup, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

ButtonGroup.handledProps = ['as', 'attached', 'basic', 'children', 'className', 'color', 'compact', 'floated', 'fluid', 'icon', 'inverted', 'labeled', 'negative', 'positive', 'primary', 'secondary', 'size', 'toggle', 'vertical', 'widths'];
ButtonGroup._meta = {
  name: 'ButtonGroup',
  parent: 'Button',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ButtonGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A button can be attached to the top or bottom of other content. */
  attached: _react.PropTypes.oneOf(['left', 'right', 'top', 'bottom']),

  /** Groups can be less pronounced. */
  basic: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Groups can have a shared color. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** Groups can reduce their padding to fit into tighter spaces. */
  compact: _react.PropTypes.bool,

  /** Groups can be aligned to the left or right of its container. */
  floated: _react.PropTypes.oneOf(_lib.SUI.FLOATS),

  /** Groups can take the width of their container. */
  fluid: _react.PropTypes.bool,

  /** Groups can be formatted as icons. */
  icon: _react.PropTypes.bool,

  /** Groups can be formatted to appear on dark backgrounds. */
  inverted: _react.PropTypes.bool,

  /** Groups can be formatted as labeled icon buttons. */
  labeled: _react.PropTypes.bool,

  /** Groups can hint towards a negative consequence. */
  negative: _react.PropTypes.bool,

  /** Groups can hint towards a positive consequence. */
  positive: _react.PropTypes.bool,

  /** Groups can be formatted to show different levels of emphasis. */
  primary: _react.PropTypes.bool,

  /** Groups can be formatted to show different levels of emphasis. */
  secondary: _react.PropTypes.bool,

  /** Groups can have different sizes. */
  size: _react.PropTypes.oneOf(_lib.SUI.SIZES),

  /** Groups can be formatted to toggle on and off. */
  toggle: _react.PropTypes.bool,

  /** Groups can be formatted to appear vertically. */
  vertical: _react.PropTypes.bool,

  /** Groups can have their widths divided evenly. */
  widths: _react.PropTypes.oneOf(_lib.SUI.WIDTHS)
} : void 0;

exports.default = ButtonGroup;