'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Button = require('../../elements/Button');

var _Button2 = _interopRequireDefault(_Button);

var _FormField = require('./FormField');

var _FormField2 = _interopRequireDefault(_FormField);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Sugar for <Form.Field control={Button} />.
 * @see Button
 * @see Form
 */
function FormButton(props) {
  var control = props.control;

  var rest = (0, _lib.getUnhandledProps)(FormButton, props);
  var ElementType = (0, _lib.getElementType)(FormButton, props);

  return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { control: control }));
}

FormButton.handledProps = ['as', 'control'];
FormButton._meta = {
  name: 'FormButton',
  parent: 'Form',
  type: _lib.META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormButton.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A FormField control prop. */
  control: _FormField2.default.propTypes.control
} : void 0;

FormButton.defaultProps = {
  as: _FormField2.default,
  control: _Button2.default
};

exports.default = FormButton;