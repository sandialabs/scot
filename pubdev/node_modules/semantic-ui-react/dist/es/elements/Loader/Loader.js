import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useKeyOrValueAndKey } from '../../lib';

/**
 * A loader alerts a user to wait for an activity to complete.
 * @see Dimmer
 */
function Loader(props) {
  var active = props.active,
      children = props.children,
      className = props.className,
      content = props.content,
      disabled = props.disabled,
      indeterminate = props.indeterminate,
      inline = props.inline,
      inverted = props.inverted,
      size = props.size;


  var classes = cx('ui', size, useKeyOnly(active, 'active'), useKeyOnly(disabled, 'disabled'), useKeyOnly(indeterminate, 'indeterminate'), useKeyOnly(inverted, 'inverted'), useKeyOnly(children || content, 'text'), useKeyOrValueAndKey(inline, 'inline'), 'loader', className);
  var rest = getUnhandledProps(Loader, props);
  var ElementType = getElementType(Loader, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

Loader.handledProps = ['active', 'as', 'children', 'className', 'content', 'disabled', 'indeterminate', 'inline', 'inverted', 'size'];
Loader._meta = {
  name: 'Loader',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Loader.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A loader can be active or visible. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** A loader can be disabled or hidden. */
  disabled: PropTypes.bool,

  /** A loader can show it's unsure of how long a task will take. */
  indeterminate: PropTypes.bool,

  /** Loaders can appear inline with content. */
  inline: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['centered'])]),

  /** Loaders can have their colors inverted. */
  inverted: PropTypes.bool,

  /** Loaders can have different sizes. */
  size: PropTypes.oneOf(SUI.SIZES)
} : void 0;

export default Loader;