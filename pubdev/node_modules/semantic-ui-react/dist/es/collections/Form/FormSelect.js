import _extends from 'babel-runtime/helpers/extends';
import React from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Select from '../../addons/Select';
import FormField from './FormField';

/**
 * Sugar for <Form.Field control={Select} />.
 * @see Form
 * @see Select
 */
function FormSelect(props) {
  var control = props.control;

  var rest = getUnhandledProps(FormSelect, props);
  var ElementType = getElementType(FormSelect, props);

  return React.createElement(ElementType, _extends({}, rest, { control: control }));
}

FormSelect.handledProps = ['as', 'control'];
FormSelect._meta = {
  name: 'FormSelect',
  parent: 'Form',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormSelect.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A FormField control prop. */
  control: FormField.propTypes.control
} : void 0;

FormSelect.defaultProps = {
  as: FormField,
  control: Select
};

export default FormSelect;