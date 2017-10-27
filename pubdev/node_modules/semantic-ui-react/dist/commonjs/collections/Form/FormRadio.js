'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Radio = require('../../addons/Radio');

var _Radio2 = _interopRequireDefault(_Radio);

var _FormField = require('./FormField');

var _FormField2 = _interopRequireDefault(_FormField);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Sugar for <Form.Field control={Radio} />.
 * @see Form
 * @see Radio
 */
function FormRadio(props) {
  var control = props.control;

  var rest = (0, _lib.getUnhandledProps)(FormRadio, props);
  var ElementType = (0, _lib.getElementType)(FormRadio, props);

  return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { control: control }));
}

FormRadio.handledProps = ['as', 'control'];
FormRadio._meta = {
  name: 'FormRadio',
  parent: 'Form',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormRadio.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A FormField control prop. */
  control: _FormField2.default.propTypes.control
} : void 0;

FormRadio.defaultProps = {
  as: _FormField2.default,
  control: _Radio2.default
};

exports.default = FormRadio;