import _toConsumableArray from 'babel-runtime/helpers/toConsumableArray';
import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useWidthProp } from '../../lib';

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


  var classes = cx(useKeyOnly(grouped, 'grouped'), useKeyOnly(inline, 'inline'), useWidthProp(widths, null, true), 'fields', className);
  var rest = getUnhandledProps(FormGroup, props);
  var ElementType = getElementType(FormGroup, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

FormGroup.handledProps = ['as', 'children', 'className', 'grouped', 'inline', 'widths'];
FormGroup._meta = {
  name: 'FormGroup',
  parent: 'Form',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? FormGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Fields can show related choices. */
  grouped: customPropTypes.every([customPropTypes.disallow(['inline']), PropTypes.bool]),

  /** Multiple fields may be inline in a row. */
  inline: customPropTypes.every([customPropTypes.disallow(['grouped']), PropTypes.bool]),

  /** Fields Groups can specify their width in grid columns or automatically divide fields to be equal width. */
  widths: PropTypes.oneOf([].concat(_toConsumableArray(SUI.WIDTHS), ['equal']))
} : void 0;

export default FormGroup;