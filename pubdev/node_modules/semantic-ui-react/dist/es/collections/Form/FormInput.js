import _extends from 'babel-runtime/helpers/extends';
import React from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Input from '../../elements/Input';
import FormField from './FormField';

/**
 * Sugar for <Form.Field control={Input} />.
 * @see Form
 * @see Input
 */
function FormInput(props) {
  var control = props.control;

  var rest = getUnhandledProps(FormInput, props);
  var ElementType = getElementType(FormInput, props);

  return React.createElement(ElementType, _extends({}, rest, { control: control }));
}

FormInput.handledProps = ['as', 'control'];
FormInput._meta = {
  name: 'FormInput',
  parent: 'Form',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormInput.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A FormField control prop. */
  control: FormField.propTypes.control
} : void 0;

FormInput.defaultProps = {
  as: FormField,
  control: Input
};

export default FormInput;