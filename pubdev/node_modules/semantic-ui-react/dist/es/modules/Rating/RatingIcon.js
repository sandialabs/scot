import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import cx from 'classnames';
import React, { Component, PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly, keyboardKey } from '../../lib';

/**
 * An internal icon sub-component for Rating component
 */

var RatingIcon = function (_Component) {
  _inherits(RatingIcon, _Component);

  function RatingIcon() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, RatingIcon);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = RatingIcon.__proto__ || Object.getPrototypeOf(RatingIcon)).call.apply(_ref, [this].concat(args))), _this), _this.defaultProps = {
      as: 'i'
    }, _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _this.handleKeyUp = function (e) {
      var _this$props = _this.props,
          onClick = _this$props.onClick,
          onKeyUp = _this$props.onKeyUp;


      if (onKeyUp) onKeyUp(e, _this.props);

      if (onClick) {
        switch (keyboardKey.getCode(e)) {
          case keyboardKey.Enter:
          case keyboardKey.Spacebar:
            e.preventDefault();
            onClick(e, _this.props);
            break;
          default:
            return;
        }
      }
    }, _this.handleMouseEnter = function (e) {
      var onMouseEnter = _this.props.onMouseEnter;


      if (onMouseEnter) onMouseEnter(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(RatingIcon, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          className = _props.className,
          selected = _props.selected;

      var classes = cx(useKeyOnly(active, 'active'), useKeyOnly(selected, 'selected'), 'icon', className);
      var rest = getUnhandledProps(RatingIcon, this.props);
      var ElementType = getElementType(RatingIcon, this.props);

      return React.createElement(ElementType, _extends({}, rest, {
        className: classes,
        onClick: this.handleClick,
        onKeyUp: this.handleKeyUp,
        onMouseEnter: this.handleMouseEnter,
        tabIndex: 0,
        role: 'radio'
      }));
    }
  }]);

  return RatingIcon;
}(Component);

RatingIcon._meta = {
  name: 'RatingIcon',
  parent: 'Rating',
  type: META.TYPES.MODULE
};
export default RatingIcon;
process.env.NODE_ENV !== "production" ? RatingIcon.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Indicates activity of an icon. */
  active: PropTypes.bool,

  /** Additional classes. */
  className: PropTypes.string,

  /** An index of icon inside Rating. */
  index: PropTypes.number,

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func,

  /**
   * Called on keyup.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onKeyUp: PropTypes.func,

  /**
   * Called on mouseenter.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onMouseEnter: PropTypes.func,

  /** Indicates selection of an icon. */
  selected: PropTypes.bool
} : void 0;
RatingIcon.handledProps = ['active', 'as', 'className', 'index', 'onClick', 'onKeyUp', 'onMouseEnter', 'selected'];