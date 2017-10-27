import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useTextAlignProp } from '../../lib';

/**
 * A container limits content to a maximum width.
 */
function Container(props) {
  var children = props.children,
      className = props.className,
      fluid = props.fluid,
      text = props.text,
      textAlign = props.textAlign;

  var classes = cx('ui', useKeyOnly(text, 'text'), useKeyOnly(fluid, 'fluid'), useTextAlignProp(textAlign), 'container', className);
  var rest = getUnhandledProps(Container, props);
  var ElementType = getElementType(Container, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

Container.handledProps = ['as', 'children', 'className', 'fluid', 'text', 'textAlign'];
Container._meta = {
  name: 'Container',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Container.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Container has no maximum with. */
  fluid: PropTypes.bool,

  /** Reduce maximum width to more naturally accommodate text. */
  text: PropTypes.bool,

  /** Align container text. */
  textAlign: PropTypes.oneOf(SUI.TEXT_ALIGNMENTS)
} : void 0;

export default Container;