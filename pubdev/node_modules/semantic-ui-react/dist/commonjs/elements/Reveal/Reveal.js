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

var _RevealContent = require('./RevealContent');

var _RevealContent2 = _interopRequireDefault(_RevealContent);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A reveal displays additional content in place of previous content when activated.
 */
function Reveal(props) {
  var active = props.active,
      animated = props.animated,
      children = props.children,
      className = props.className,
      disabled = props.disabled,
      instant = props.instant;


  var classes = (0, _classnames2.default)('ui', animated, (0, _lib.useKeyOnly)(active, 'active'), (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(instant, 'instant'), 'reveal', className);
  var rest = (0, _lib.getUnhandledProps)(Reveal, props);
  var ElementType = (0, _lib.getElementType)(Reveal, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

Reveal.handledProps = ['active', 'animated', 'as', 'children', 'className', 'disabled', 'instant'];
Reveal._meta = {
  name: 'Reveal',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Reveal.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** An active reveal displays its hidden content. */
  active: _react.PropTypes.bool,

  /** An animation name that will be applied to Reveal. */
  animated: _react.PropTypes.oneOf(['fade', 'small fade', 'move', 'move right', 'move up', 'move down', 'rotate', 'rotate left']),

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A disabled reveal will not animate when hovered. */
  disabled: _react.PropTypes.bool,

  /** An element can show its content without delay. */
  instant: _react.PropTypes.bool
} : void 0;

Reveal.Content = _RevealContent2.default;

exports.default = Reveal;