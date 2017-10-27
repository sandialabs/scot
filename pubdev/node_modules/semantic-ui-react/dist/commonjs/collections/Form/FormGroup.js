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

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A set of fields can appear grouped together.
 * @see Form
 */
function FormGroup(props) {
  var children = props.children,
      className = props.className,
      grouped = props.grouped,
      inline = props.inline,
      widths = props.widths;


  var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(grouped, 'grouped'), (0, _lib.useKeyOnly)(inline, 'inline'), (0, _lib.useWidthProp)(widths, null, true), 'fields', className);
  var rest = (0, _lib.getUnhandledProps)(FormGroup, props);
  var ElementType = (0, _lib.getElementType)(FormGroup, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

FormGroup.handledProps = ['as', 'children', 'className', 'grouped', 'inline', 'widths'];
FormGroup._meta = {
  name: 'FormGroup',
  parent: 'Form',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Fields can show related choices. */
  grouped: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['inline']), _react.PropTypes.bool]),

  /** Multiple fields may be inline in a row. */
  inline: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['grouped']), _react.PropTypes.bool]),

  /** Fields Groups can specify their width in grid columns or automatically divide fields to be equal width. */
  widths: _react.PropTypes.oneOf([].concat((0, _toConsumableArray3.default)(_lib.SUI.WIDTHS), ['equal']))
} : void 0;

exports.default = FormGroup;