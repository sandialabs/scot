import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { Component, PropTypes } from 'react';

import { childrenUtils, createShorthand, customPropTypes, META, getElementType, getUnhandledProps, useKeyOnly } from '../../lib';
import Flag from '../../elements/Flag';
import Icon from '../../elements/Icon';
import Image from '../../elements/Image';
import Label from '../../elements/Label';

/**
 * An item sub-component for Dropdown component.
 */

var DropdownItem = function (_Component) {
  _inherits(DropdownItem, _Component);

  function DropdownItem() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, DropdownItem);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = DropdownItem.__proto__ || Object.getPrototypeOf(DropdownItem)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(DropdownItem, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          content = _props.content,
          disabled = _props.disabled,
          description = _props.description,
          flag = _props.flag,
          icon = _props.icon,
          image = _props.image,
          label = _props.label,
          selected = _props.selected,
          text = _props.text;


      var classes = cx(useKeyOnly(active, 'active'), useKeyOnly(disabled, 'disabled'), useKeyOnly(selected, 'selected'), 'item', className);
      // add default dropdown icon if item contains another menu
      var iconName = _isNil(icon) ? childrenUtils.someByType(children, 'DropdownMenu') && 'dropdown' : icon;
      var rest = getUnhandledProps(DropdownItem, this.props);
      var ElementType = getElementType(DropdownItem, this.props);
      var ariaOptions = {
        role: 'option',
        'aria-disabled': disabled,
        'aria-checked': active,
        'aria-selected': selected
      };

      if (!_isNil(children)) {
        return React.createElement(
          ElementType,
          _extends({}, rest, ariaOptions, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      var flagElement = Flag.create(flag);
      var iconElement = Icon.create(iconName);
      var imageElement = Image.create(image);
      var labelElement = Label.create(label);
      var descriptionElement = createShorthand('span', function (val) {
        return { children: val };
      }, description, function (props) {
        return { className: 'description' };
      });
      var textElement = createShorthand('span', function (val) {
        return { children: val };
      }, content || text, function (props) {
        return { className: 'text' };
      });

      return React.createElement(
        ElementType,
        _extends({}, rest, ariaOptions, { className: classes, onClick: this.handleClick }),
        imageElement,
        iconElement,
        flagElement,
        labelElement,
        descriptionElement,
        textElement
      );
    }
  }]);

  return DropdownItem;
}(Component);

DropdownItem._meta = {
  name: 'DropdownItem',
  parent: 'Dropdown',
  type: META.TYPES.MODULE
};
export default DropdownItem;
process.env.NODE_ENV !== "production" ? DropdownItem.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Style as the currently chosen item. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** Additional text with less emphasis. */
  description: customPropTypes.itemShorthand,

  /** A dropdown item can be disabled. */
  disabled: PropTypes.bool,

  /** Shorthand for Flag. */
  flag: customPropTypes.itemShorthand,

  /** Shorthand for Icon. */
  icon: customPropTypes.itemShorthand,

  /** Shorthand for Image. */
  image: customPropTypes.itemShorthand,

  /** Shorthand for Label. */
  label: customPropTypes.itemShorthand,

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func,

  /**
   * The item currently selected by keyboard shortcut.
   * This is not the active item.
   */
  selected: PropTypes.bool,

  /** Display text. */
  text: customPropTypes.contentShorthand,

  /** Stored value. */
  value: PropTypes.oneOfType([PropTypes.number, PropTypes.string])
} : void 0;
DropdownItem.handledProps = ['active', 'as', 'children', 'className', 'content', 'description', 'disabled', 'flag', 'icon', 'image', 'label', 'onClick', 'selected', 'text', 'value'];