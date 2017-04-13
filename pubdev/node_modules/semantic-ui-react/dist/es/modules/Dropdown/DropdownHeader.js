import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';
import Icon from '../../elements/Icon';

/**
 * A dropdown menu can contain a header.
 */
function DropdownHeader(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      icon = props.icon;


  var classes = cx('header', className);
  var rest = getUnhandledProps(DropdownHeader, props);
  var ElementType = getElementType(DropdownHeader, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    Icon.create(icon),
    content
  );
}

DropdownHeader.handledProps = ['as', 'children', 'className', 'content', 'icon'];
DropdownHeader._meta = {
  name: 'DropdownHeader',
  parent: 'Dropdown',
  type: META.TYPES.MODULE
};

process.env.NODE_ENV !== "production" ? DropdownHeader.propTypes = {
  /** An element type to render as (string or function) */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Shorthand for Icon. */
  icon: customPropTypes.itemShorthand
} : void 0;

export default DropdownHeader;