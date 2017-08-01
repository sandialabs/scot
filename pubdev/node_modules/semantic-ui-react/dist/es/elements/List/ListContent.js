import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META, SUI, useValueAndKey, useVerticalAlignProp } from '../../lib';
import ListDescription from './ListDescription';
import ListHeader from './ListHeader';

/**
 * A list item can contain a content.
 */
function ListContent(props) {
  var children = props.children,
      className = props.className,
      content = props.content,
      description = props.description,
      floated = props.floated,
      header = props.header,
      verticalAlign = props.verticalAlign;


  var classes = cx(useValueAndKey(floated, 'floated'), useVerticalAlignProp(verticalAlign), 'content', className);
  var rest = getUnhandledProps(ListContent, props);
  var ElementType = getElementType(ListContent, props);

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
    ListHeader.create(header),
    ListDescription.create(description),
    content
  );
}

ListContent.handledProps = ['as', 'children', 'className', 'content', 'description', 'floated', 'header', 'verticalAlign'];
ListContent._meta = {
  name: 'ListContent',
  parent: 'List',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ListContent.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Shorthand for ListDescription. */
  description: customPropTypes.itemShorthand,

  /** An list content can be floated left or right. */
  floated: PropTypes.oneOf(SUI.FLOATS),

  /** Shorthand for ListHeader. */
  header: customPropTypes.itemShorthand,

  /** An element inside a list can be vertically aligned. */
  verticalAlign: PropTypes.oneOf(SUI.VERTICAL_ALIGNMENTS)
} : void 0;

ListContent.create = createShorthandFactory(ListContent, function (content) {
  return { content: content };
});

export default ListContent;