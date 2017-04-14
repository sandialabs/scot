import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isUndefined from 'lodash/isUndefined';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { Component, PropTypes } from 'react';

import { createShorthand, createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useKeyOrValueAndKey, useValueAndKey } from '../../lib';
import Icon from '../Icon/Icon';
import Image from '../Image/Image';
import LabelDetail from './LabelDetail';
import LabelGroup from './LabelGroup';

/**
 * A label displays content classification.
 */

var Label = function (_Component) {
  _inherits(Label, _Component);

  function Label() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Label);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Label.__proto__ || Object.getPrototypeOf(Label)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _this.handleRemove = function (e) {
      var onRemove = _this.props.onRemove;


      if (onRemove) onRemove(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Label, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          attached = _props.attached,
          basic = _props.basic,
          children = _props.children,
          circular = _props.circular,
          className = _props.className,
          color = _props.color,
          content = _props.content,
          corner = _props.corner,
          detail = _props.detail,
          empty = _props.empty,
          floating = _props.floating,
          horizontal = _props.horizontal,
          icon = _props.icon,
          image = _props.image,
          onRemove = _props.onRemove,
          pointing = _props.pointing,
          removeIcon = _props.removeIcon,
          ribbon = _props.ribbon,
          size = _props.size,
          tag = _props.tag;


      var pointingClass = pointing === true && 'pointing' || (pointing === 'left' || pointing === 'right') && pointing + ' pointing' || (pointing === 'above' || pointing === 'below') && 'pointing ' + pointing;

      var classes = cx('ui', color, pointingClass, size, useKeyOnly(active, 'active'), useKeyOnly(basic, 'basic'), useKeyOnly(circular, 'circular'), useKeyOnly(empty, 'empty'), useKeyOnly(floating, 'floating'), useKeyOnly(horizontal, 'horizontal'), useKeyOnly(image === true, 'image'), useKeyOnly(tag, 'tag'), useKeyOrValueAndKey(corner, 'corner'), useKeyOrValueAndKey(ribbon, 'ribbon'), useValueAndKey(attached, 'attached'), 'label', className);
      var rest = getUnhandledProps(Label, this.props);
      var ElementType = getElementType(Label, this.props);

      if (!_isNil(children)) {
        return React.createElement(
          ElementType,
          _extends({}, rest, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      var removeIconShorthand = _isUndefined(removeIcon) ? 'delete' : removeIcon;

      return React.createElement(
        ElementType,
        _extends({ className: classes, onClick: this.handleClick }, rest),
        Icon.create(icon),
        typeof image !== 'boolean' && Image.create(image),
        content,
        createShorthand(LabelDetail, function (val) {
          return { content: val };
        }, detail),
        onRemove && Icon.create(removeIconShorthand, { onClick: this.handleRemove })
      );
    }
  }]);

  return Label;
}(Component);

Label._meta = {
  name: 'Label',
  type: META.TYPES.ELEMENT
};
Label.Detail = LabelDetail;
Label.Group = LabelGroup;
export default Label;
process.env.NODE_ENV !== "production" ? Label.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A label can be active. */
  active: PropTypes.bool,

  /** A label can attach to a content segment. */
  attached: PropTypes.oneOf(['top', 'bottom', 'top right', 'top left', 'bottom left', 'bottom right']),

  /** A label can reduce its complexity. */
  basic: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** A label can be circular. */
  circular: PropTypes.bool,

  /** Additional classes. */
  className: PropTypes.string,

  /** Color of the label. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** A label can position itself in the corner of an element. */
  corner: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['left', 'right'])]),

  /** Shorthand for LabelDetail. */
  detail: customPropTypes.itemShorthand,

  /** Formats the label as a dot. */
  empty: customPropTypes.every([PropTypes.bool, customPropTypes.demand(['circular'])]),

  /** Float above another element in the upper right corner. */
  floating: PropTypes.bool,

  /** A horizontal label is formatted to label content along-side it horizontally. */
  horizontal: PropTypes.bool,

  /** Shorthand for Icon. */
  icon: customPropTypes.itemShorthand,

  /** A label can be formatted to emphasize an image or prop can be used as shorthand for Image. */
  image: PropTypes.oneOfType([PropTypes.bool, customPropTypes.itemShorthand]),

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func,

  /**
   * Adds an "x" icon, called when "x" is clicked.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onRemove: PropTypes.func,

  /** A label can point to content next to it. */
  pointing: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['above', 'below', 'left', 'right'])]),

  /** Shorthand for Icon to appear as the last child and trigger onRemove. */
  removeIcon: customPropTypes.itemShorthand,

  /** A label can appear as a ribbon attaching itself to an element. */
  ribbon: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['right'])]),

  /** A label can have different sizes. */
  size: PropTypes.oneOf(SUI.SIZES),

  /** A label can appear as a tag. */
  tag: PropTypes.bool
} : void 0;
Label.handledProps = ['active', 'as', 'attached', 'basic', 'children', 'circular', 'className', 'color', 'content', 'corner', 'detail', 'empty', 'floating', 'horizontal', 'icon', 'image', 'onClick', 'onRemove', 'pointing', 'removeIcon', 'ribbon', 'size', 'tag'];


Label.create = createShorthandFactory(Label, function (value) {
  return { content: value };
});