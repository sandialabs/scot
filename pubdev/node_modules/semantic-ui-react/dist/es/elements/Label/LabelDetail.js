import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

function LabelDetail(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('detail', className);
  var rest = getUnhandledProps(LabelDetail, props);
  var ElementType = getElementType(LabelDetail, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

LabelDetail.handledProps = ['as', 'children', 'className', 'content'];
LabelDetail._meta = {
  name: 'LabelDetail',
  parent: 'Label',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? LabelDetail.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

export default LabelDetail;