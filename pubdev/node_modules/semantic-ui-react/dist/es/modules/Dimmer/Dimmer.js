import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { Component, PropTypes } from 'react';

import { createShorthandFactory, customPropTypes, getElementType, getUnhandledProps, isBrowser, META, useKeyOnly } from '../../lib';
import Portal from '../../addons/Portal';
import DimmerDimmable from './DimmerDimmable';

/**
 * A dimmer hides distractions to focus attention on particular content.
 */

var Dimmer = function (_Component) {
  _inherits(Dimmer, _Component);

  function Dimmer() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Dimmer);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Dimmer.__proto__ || Object.getPrototypeOf(Dimmer)).call.apply(_ref, [this].concat(args))), _this), _this.handlePortalMount = function () {
      if (isBrowser) document.body.classList.add('dimmed', 'dimmable');
    }, _this.handlePortalUnmount = function () {
      if (isBrowser) document.body.classList.remove('dimmed', 'dimmable');
    }, _this.handleClick = function (e) {
      var _this$props = _this.props,
          onClick = _this$props.onClick,
          onClickOutside = _this$props.onClickOutside;


      if (onClick) onClick(e, _this.props);
      if (_this.centerRef && _this.centerRef !== e.target && _this.centerRef.contains(e.target)) return;
      if (onClickOutside) onClickOutside(e, _this.props);
    }, _this.handleCenterRef = function (c) {
      return _this.centerRef = c;
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Dimmer, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          content = _props.content,
          disabled = _props.disabled,
          inverted = _props.inverted,
          page = _props.page,
          simple = _props.simple;


      var classes = cx('ui', useKeyOnly(active, 'active transition visible'), useKeyOnly(disabled, 'disabled'), useKeyOnly(inverted, 'inverted'), useKeyOnly(page, 'page'), useKeyOnly(simple, 'simple'), 'dimmer', className);
      var rest = getUnhandledProps(Dimmer, this.props);
      var ElementType = getElementType(Dimmer, this.props);

      var childrenContent = _isNil(children) ? content : children;

      var dimmerElement = React.createElement(
        ElementType,
        _extends({}, rest, { className: classes, onClick: this.handleClick }),
        childrenContent && React.createElement(
          'div',
          { className: 'content' },
          React.createElement(
            'div',
            { className: 'center', ref: this.handleCenterRef },
            childrenContent
          )
        )
      );

      if (page) {
        return React.createElement(
          Portal,
          {
            closeOnEscape: false,
            closeOnDocumentClick: false,
            onMount: this.handlePortalMount,
            onUnmount: this.handlePortalUnmount,
            open: active,
            openOnTriggerClick: false
          },
          dimmerElement
        );
      }

      return dimmerElement;
    }
  }]);

  return Dimmer;
}(Component);

Dimmer._meta = {
  name: 'Dimmer',
  type: META.TYPES.MODULE
};
Dimmer.Dimmable = DimmerDimmable;
export default Dimmer;
process.env.NODE_ENV !== "production" ? Dimmer.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** An active dimmer will dim its parent container. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /** A disabled dimmer cannot be activated */
  disabled: PropTypes.bool,

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func,

  /**
   * Handles click outside Dimmer's content, but inside Dimmer area.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClickOutside: PropTypes.func,

  /** A dimmer can be formatted to have its colors inverted. */
  inverted: PropTypes.bool,

  /** A dimmer can be formatted to be fixed to the page. */
  page: PropTypes.bool,

  /** A dimmer can be controlled with simple prop. */
  simple: PropTypes.bool
} : void 0;
Dimmer.handledProps = ['active', 'as', 'children', 'className', 'content', 'disabled', 'inverted', 'onClick', 'onClickOutside', 'page', 'simple'];


Dimmer.create = createShorthandFactory(Dimmer, function (value) {
  return { content: value };
});