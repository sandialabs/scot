import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * A list can contain a sub list.
 */
function ListList(props) {
  var children = props.children,
      className = props.className;


  var rest = getUnhandledProps(ListList, props);
  var ElementType = getElementType(ListList, props);
  var classes = cx(useKeyOnly(ElementType !== 'ul' && ElementType !== 'ol', 'list'), className);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

ListList.handledProps = ['as', 'children', 'className'];
ListList._meta = {
  name: 'ListList',
  parent: 'List',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ListList.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default ListList;