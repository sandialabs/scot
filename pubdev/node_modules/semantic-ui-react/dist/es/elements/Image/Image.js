import _extends from 'babel-runtime/helpers/extends';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useKeyOrValueAndKey, useValueAndKey, useVerticalAlignProp } from '../../lib';
import Dimmer from '../../modules/Dimmer';
import Label from '../Label/Label';

import ImageGroup from './ImageGroup';

/**
 * An image is a graphic representation of something.
 * @see Icon
 */
function Image(props) {
  var alt = props.alt,
      avatar = props.avatar,
      bordered = props.bordered,
      centered = props.centered,
      children = props.children,
      className = props.className,
      dimmer = props.dimmer,
      disabled = props.disabled,
      floated = props.floated,
      fluid = props.fluid,
      height = props.height,
      hidden = props.hidden,
      href = props.href,
      inline = props.inline,
      label = props.label,
      shape = props.shape,
      size = props.size,
      spaced = props.spaced,
      src = props.src,
      verticalAlign = props.verticalAlign,
      width = props.width,
      wrapped = props.wrapped,
      ui = props.ui;


  var classes = cx(useKeyOnly(ui, 'ui'), size, shape, useKeyOnly(avatar, 'avatar'), useKeyOnly(bordered, 'bordered'), useKeyOnly(centered, 'centered'), useKeyOnly(disabled, 'disabled'), useKeyOnly(fluid, 'fluid'), useKeyOnly(hidden, 'hidden'), useKeyOnly(inline, 'inline'), useKeyOrValueAndKey(spaced, 'spaced'), useValueAndKey(floated, 'floated'), useVerticalAlignProp(verticalAlign, 'aligned'), 'image', className);
  var rest = getUnhandledProps(Image, props);
  var ElementType = getElementType(Image, props, function () {
    if (!_isNil(dimmer) || !_isNil(label) || !_isNil(wrapped) || !_isNil(children)) return 'div';
  });

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  var rootProps = _extends({}, rest, { className: classes });
  var imgTagProps = { alt: alt, src: src, height: height, width: width };

  if (ElementType === 'img') return React.createElement(ElementType, _extends({}, rootProps, imgTagProps));

  return React.createElement(
    ElementType,
    _extends({}, rootProps, { href: href }),
    Dimmer.create(dimmer),
    Label.create(label),
    React.createElement('img', imgTagProps)
  );
}

Image.handledProps = ['alt', 'as', 'avatar', 'bordered', 'centered', 'children', 'className', 'dimmer', 'disabled', 'floated', 'fluid', 'height', 'hidden', 'href', 'inline', 'label', 'shape', 'size', 'spaced', 'src', 'ui', 'verticalAlign', 'width', 'wrapped'];
Image.Group = ImageGroup;

Image._meta = {
  name: 'Image',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Image.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Alternate text for the image specified. */
  alt: PropTypes.string,

  /** An image may be formatted to appear inline with text as an avatar. */
  avatar: PropTypes.bool,

  /** An image may include a border to emphasize the edges of white or transparent content. */
  bordered: PropTypes.bool,

  /** An image can appear centered in a content block. */
  centered: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** An image can show that it is disabled and cannot be selected. */
  disabled: PropTypes.bool,

  /** Shorthand for Dimmer. */
  dimmer: customPropTypes.itemShorthand,

  /** An image can sit to the left or right of other content. */
  floated: PropTypes.oneOf(SUI.FLOATS),

  /** An image can take up the width of its container. */
  fluid: customPropTypes.every([PropTypes.bool, customPropTypes.disallow(['size'])]),

  /** The img element height attribute. */
  height: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),

  /** An image can be hidden. */
  hidden: PropTypes.bool,

  /** Renders the Image as an <a> tag with this href. */
  href: PropTypes.string,

  /** An image may appear inline. */
  inline: PropTypes.bool,

  /** Shorthand for Label. */
  label: customPropTypes.itemShorthand,

  /** An image may appear rounded or circular. */
  shape: PropTypes.oneOf(['rounded', 'circular']),

  /** An image may appear at different sizes. */
  size: PropTypes.oneOf(SUI.SIZES),

  /** An image can specify that it needs an additional spacing to separate it from nearby content. */
  spaced: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['left', 'right'])]),

  /** Specifies the URL of the image. */
  src: PropTypes.string,

  /** Whether or not to add the ui className. */
  ui: PropTypes.bool,

  /** An image can specify its vertical alignment. */
  verticalAlign: PropTypes.oneOf(SUI.VERTICAL_ALIGNMENTS),

  /** The img element width attribute. */
  width: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),

  /** An image can render wrapped in a `div.ui.image` as alternative HTML markup. */
  wrapped: customPropTypes.every([PropTypes.bool,
  // these props wrap the image in an a tag already
  customPropTypes.disallow(['href'])])
} : void 0;

Image.defaultProps = {
  as: 'img',
  ui: true
};

Image.create = createShorthandFactory(Image, function (value) {
  return { src: value };
});

export default Image;