import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';

import React, { PropTypes } from 'react';
import cx from 'classnames';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly, createShorthandFactory } from '../../lib';

/**
 * A content sub-component for Accordion component.
 */
function AccordionContent(props) {
  var active = props.active,
      children = props.children,
      className = props.className,
      content = props.content;

  var classes = cx('content', useKeyOnly(active, 'active'), className);
  var rest = getUnhandledProps(AccordionContent, props);
  var ElementType = getElementType(AccordionContent, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    _isNil(children) ? content : children
  );
}

AccordionContent.handledProps = ['active', 'as', 'children', 'className', 'content'];
process.env.NODE_ENV !== "production" ? AccordionContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Whether or not the content is visible. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand
} : void 0;

AccordionContent._meta = {
  name: 'AccordionContent',
  type: META.TYPES.MODULE,
  parent: 'Accordion'
};

AccordionContent.create = createShorthandFactory(AccordionContent, function (content) {
  return { content: content };
});

export default AccordionContent;