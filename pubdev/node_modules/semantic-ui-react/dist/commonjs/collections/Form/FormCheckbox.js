'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Checkbox = require('../../modules/Checkbox');

var _Checkbox2 = _interopRequireDefault(_Checkbox);

var _FormField = require('./FormField');

var _FormField2 = _interopRequireDefault(_FormField);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Sugar for <Form.Field control={Checkbox} />.
 * @see Checkbox
 * @see Form
 */
function FormCheckbox(props) {
  var control = props.control;

  var rest = (0, _lib.getUnhandledProps)(FormCheckbox, props);
  var ElementType = (0, _lib.getElementType)(FormCheckbox, props);

  return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { control: control }));
}

FormCheckbox.handledProps = ['as', 'control'];
FormCheckbox._meta = {
  name: 'FormCheckbox',
  parent: 'Form',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormCheckbox.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A FormField control prop. */
  control: _FormField2.default.propTypes.control
} : void 0;

FormCheckbox.defaultProps = {
  as: _FormField2.default,
  control: _Checkbox2.default
};

exports.default = FormCheckbox;