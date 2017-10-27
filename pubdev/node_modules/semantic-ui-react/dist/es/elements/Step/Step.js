import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { Component, PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';
import Icon from '../../elements/Icon';

import StepContent from './StepContent';
import StepDescription from './StepDescription';
import StepGroup from './StepGroup';
import StepTitle from './StepTitle';

/**
 * A step shows the completion status of an activity in a series of activities.
 */

var Step = function (_Component) {
  _inherits(Step, _Component);

  function Step() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Step);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Step.__proto__ || Object.getPrototypeOf(Step)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Step, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          completed = _props.completed,
          description = _props.description,
          disabled = _props.disabled,
          href = _props.href,
          icon = _props.icon,
          link = _props.link,
          onClick = _props.onClick,
          title = _props.title;


      var classes = cx(useKeyOnly(active, 'active'), useKeyOnly(completed, 'completed'), useKeyOnly(disabled, 'disabled'), useKeyOnly(link, 'link'), 'step', className);
      var rest = getUnhandledProps(Step, this.props);
      var ElementType = getElementType(Step, this.props, function () {
        if (onClick) return 'a';
      });

      if (!_isNil(children)) {
        return React.createElement(
          ElementType,
          _extends({}, rest, { className: classes, href: href, onClick: this.handleClick }),
          children
        );
      }

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes, href: href, onClick: this.handleClick }),
        Icon.create(icon),
        React.createElement(StepContent, { description: description, title: title })
      );
    }
  }]);

  return Step;
}(Component);

Step._meta = {
  name: 'Step',
  type: META.TYPES.ELEMENT
};
Step.Content = StepContent;
Step.Description = StepDescription;
Step.Group = StepGroup;
Step.Title = StepTitle;
export default Step;
process.env.NODE_ENV !== "production" ? Step.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A step can be highlighted as active. */
  active: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A step can show that a user has completed it. */
  completed: PropTypes.bool,

  /** Shorthand for StepDescription. */
  description: customPropTypes.itemShorthand,

  /** Show that the Loader is inactive. */
  disabled: PropTypes.bool,

  /** Render as an `a` tag instead of a `div` and adds the href attribute. */
  href: PropTypes.string,

  /** Shorthand for Icon. */
  icon: customPropTypes.itemShorthand,

  /** A step can be link. */
  link: PropTypes.bool,

  /**
   * Called on click. When passed, the component will render as an `a`
   * tag by default instead of a `div`.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func,

  /** A step can show a ordered sequence of steps. Passed from StepGroup. */
  ordered: PropTypes.bool,

  /** Shorthand for StepTitle. */
  title: customPropTypes.itemShorthand
} : void 0;
Step.handledProps = ['active', 'as', 'children', 'className', 'completed', 'description', 'disabled', 'href', 'icon', 'link', 'onClick', 'ordered', 'title'];