import _extends from 'babel-runtime/helpers/extends';
import React from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Dropdown from '../../modules/Dropdown';
import FormField from './FormField';

/**
 * Sugar for <Form.Field control={Dropdown} />.
 * @see Dropdown
 * @see Form
 */
function FormDropdown(props) {
  var control = props.control;

  var rest = getUnhandledProps(FormDropdown, props);
  var ElementType = getElementType(FormDropdown, props);

  return React.createElement(ElementType, _extends({}, rest, { control: control }));
}

FormDropdown.handledProps = ['as', 'control'];
FormDropdown._meta = {
  name: 'FormDropdown',
  parent: 'Form',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormDropdown.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A FormField control prop. */
  control: FormField.propTypes.control
} : void 0;

FormDropdown.defaultProps = {
  as: FormField,
  control: Dropdown
};

export default FormDropdown;