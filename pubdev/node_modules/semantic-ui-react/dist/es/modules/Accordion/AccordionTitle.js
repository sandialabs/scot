import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { Component, PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly, createShorthandFactory } from '../../lib';

import Icon from '../../elements/Icon';

/**
 * A title sub-component for Accordion component.
 */

var AccordionTitle = function (_Component) {
  _inherits(AccordionTitle, _Component);

  function AccordionTitle() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, AccordionTitle);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = AccordionTitle.__proto__ || Object.getPrototypeOf(AccordionTitle)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(AccordionTitle, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          content = _props.content;


      var classes = cx(useKeyOnly(active, 'active'), 'title', className);
      var rest = getUnhandledProps(AccordionTitle, this.props);
      var ElementType = getElementType(AccordionTitle, this.props);

      if (_isNil(content)) {
        return React.createElement(
          ElementType,
          _extends({}, rest, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes, onClick: this.handleClick }),
        React.createElement(Icon, { name: 'dropdown' }),
        content
      );
    }
  }]);

  return AccordionTitle;
}(Component);

AccordionTitle._meta = {
  name: 'AccordionTitle',
  type: META.TYPES.MODULE,
  parent: 'Accordion'
};
export default AccordionTitle;
process.env.NODE_ENV !== "production" ? AccordionTitle.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Whether or not the title is in the open state. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content. */
  content: customPropTypes.contentShorthand,

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func
} : void 0;
AccordionTitle.handledProps = ['active', 'as', 'children', 'className', 'content', 'onClick'];


AccordionTitle.create = createShorthandFactory(AccordionTitle, function (content) {
  return { content: content };
});