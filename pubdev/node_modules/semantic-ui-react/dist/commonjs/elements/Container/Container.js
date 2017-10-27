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
 * A container limits content to a maximum width.
 */
function Container(props) {
  var children = props.children,
      className = props.className,
      fluid = props.fluid,
      text = props.text,
      textAlign = props.textAlign;

  var classes = (0, _classnames2.default)('ui', (0, _lib.useKeyOnly)(text, 'text'), (0, _lib.useKeyOnly)(fluid, 'fluid'), (0, _lib.useTextAlignProp)(textAlign), 'container', className);
  var rest = (0, _lib.getUnhandledProps)(Container, props);
  var ElementType = (0, _lib.getElementType)(Container, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

Container.handledProps = ['as', 'children', 'className', 'fluid', 'text', 'textAlign'];
Container._meta = {
  name: 'Container',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Container.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Container has no maximum with. */
  fluid: _react.PropTypes.bool,

  /** Reduce maximum width to more naturally accommodate text. */
  text: _react.PropTypes.bool,

  /** Align container text. */
  textAlign: _react.PropTypes.oneOf(_lib.SUI.TEXT_ALIGNMENTS)
} : void 0;

exports.default = Container;