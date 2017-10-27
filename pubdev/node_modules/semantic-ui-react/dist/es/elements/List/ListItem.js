import _extends from 'babel-runtime/helpers/extends';
import _isPlainObject from 'lodash/isPlainObject';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { isValidElement, PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';
import Image from '../../elements/Image';

import ListContent from './ListContent';
import ListDescription from './ListDescription';
import ListHeader from './ListHeader';
import ListIcon from './ListIcon';

/**
 * A list item can contain a set of items.
 */
function ListItem(props) {
  var active = props.active,
      children = props.children,
      className = props.className,
      content = props.content,
      description = props.description,
      disabled = props.disabled,
      header = props.header,
      icon = props.icon,
      image = props.image,
      value = props.value;


  var ElementType = getElementType(ListItem, props);
  var classes = cx(useKeyOnly(active, 'active'), useKeyOnly(disabled, 'disabled'), useKeyOnly(ElementType !== 'li', 'item'), className);
  var rest = getUnhandledProps(ListItem, props);
  var valueProp = ElementType === 'li' ? { value: value } : { 'data-value': value };

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, valueProp, { role: 'listitem', className: classes }),
      children
    );
  }

  var iconElement = ListIcon.create(icon);
  var imageElement = Image.create(image);

  // See description of `content` prop for explanation about why this is necessary.
  if (!isValidElement(content) && _isPlainObject(content)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, valueProp, { role: 'listitem', className: classes }),
      iconElement || imageElement,
      ListContent.create(content, { header: header, description: description })
    );
  }

  var headerElement = ListHeader.create(header);
  var descriptionElement = ListDescription.create(description);

  if (iconElement || imageElement) {
    return React.createElement(
      ElementType,
      _extends({}, rest, valueProp, { role: 'listitem', className: classes }),
      iconElement || imageElement,
      (content || headerElement || descriptionElement) && React.createElement(
        ListContent,
        null,
        headerElement,
        descriptionElement,
        content
      )
    );
  }

  return React.createElement(
    ElementType,
    _extends({}, rest, valueProp, { role: 'listitem', className: classes }),
    headerElement,
    descriptionElement,
    content
  );
}

ListItem.handledProps = ['active', 'as', 'children', 'className', 'content', 'description', 'disabled', 'header', 'icon', 'image', 'value'];
ListItem._meta = {
  name: 'ListItem',
  parent: 'List',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ListItem.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A list item can active. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /**
   * Shorthand for primary content.
   *
   * Heads up!
   *
   * This is handled slightly differently than the typical `content` prop since
   * the wrapping ListContent is not used when there's no icon or image.
   *
   * If you pass content as:
   * - an element/literal, it's treated as the sibling node to
   * header/description (whether wrapped in Item.Content or not).
   * - a props object, it forces the presence of Item.Content and passes those
   * props to it. If you pass a content prop within that props object, it
   * will be treated as the sibling node to header/description.
   */
  content: customPropTypes.itemShorthand,

  /** Shorthand for ListDescription. */
  description: customPropTypes.itemShorthand,

  /** A list item can disabled. */
  disabled: PropTypes.bool,

  /** Shorthand for ListHeader. */
  header: customPropTypes.itemShorthand,

  /** Shorthand for ListIcon. */
  icon: customPropTypes.every([customPropTypes.disallow(['image']), customPropTypes.itemShorthand]),

  /** Shorthand for Image. */
  image: customPropTypes.every([customPropTypes.disallow(['icon']), customPropTypes.itemShorthand]),

  /** A value for an ordered list. */
  value: PropTypes.string
} : void 0;

ListItem.create = createShorthandFactory(ListItem, function (content) {
  return { content: content };
}, true);

export default ListItem;