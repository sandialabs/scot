'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Dropdown = require('../../modules/Dropdown');

var _Dropdown2 = _interopRequireDefault(_Dropdown);

var _FormField = require('./FormField');

var _FormField2 = _interopRequireDefault(_FormField);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Sugar for <Form.Field control={Dropdown} />.
 * @see Dropdown
 * @see Form
 */
function FormDropdown(props) {
  var control = props.control;

  var rest = (0, _lib.getUnhandledProps)(FormDropdown, props);
  var ElementType = (0, _lib.getElementType)(FormDropdown, props);

  return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { control: control }));
}

FormDropdown.handledProps = ['as', 'control'];
FormDropdown._meta = {
  name: 'FormDropdown',
  parent: 'Form',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormDropdown.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A FormField control prop. */
  control: _FormField2.default.propTypes.control
} : void 0;

FormDropdown.defaultProps = {
  as: _FormField2.default,
  control: _Dropdown2.default
};

exports.default = FormDropdown;