import _extends from 'babel-runtime/helpers/extends';
import React from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Checkbox from '../../modules/Checkbox';
import FormField from './FormField';

/**
 * Sugar for <Form.Field control={Checkbox} />.
 * @see Checkbox
 * @see Form
 */
function FormCheckbox(props) {
  var control = props.control;

  var rest = getUnhandledProps(FormCheckbox, props);
  var ElementType = getElementType(FormCheckbox, props);

  return React.createElement(ElementType, _extends({}, rest, { control: control }));
}

FormCheckbox.handledProps = ['as', 'control'];
FormCheckbox._meta = {
  name: 'FormCheckbox',
  parent: 'Form',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormCheckbox.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A FormField control prop. */
  control: FormField.propTypes.control
} : void 0;

FormCheckbox.defaultProps = {
  as: FormField,
  control: Checkbox
};

export default FormCheckbox;