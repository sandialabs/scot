'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Select = require('../../addons/Select');

var _Select2 = _interopRequireDefault(_Select);

var _FormField = require('./FormField');

var _FormField2 = _interopRequireDefault(_FormField);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Sugar for <Form.Field control={Select} />.
 * @see Form
 * @see Select
 */
function FormSelect(props) {
  var control = props.control;

  var rest = (0, _lib.getUnhandledProps)(FormSelect, props);
  var ElementType = (0, _lib.getElementType)(FormSelect, props);

  return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { control: control }));
}

FormSelect.handledProps = ['as', 'control'];
FormSelect._meta = {
  name: 'FormSelect',
  parent: 'Form',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormSelect.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A FormField control prop. */
  control: _FormField2.default.propTypes.control
} : void 0;

FormSelect.defaultProps = {
  as: _FormField2.default,
  control: _Select2.default
};

exports.default = FormSelect;