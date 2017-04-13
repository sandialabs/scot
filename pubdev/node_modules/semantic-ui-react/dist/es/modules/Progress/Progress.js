import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';
import _round from 'lodash/round';
import _clamp from 'lodash/clamp';
import _isUndefined from 'lodash/isUndefined';
import _without from 'lodash/without';
import cx from 'classnames';

import React, { Component, PropTypes } from 'react';

import { createShorthand, customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useValueAndKey } from '../../lib';

/**
 * A progress bar shows the progression of a task.
 */

var Progress = function (_Component) {
  _inherits(Progress, _Component);

  function Progress() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Progress);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Progress.__proto__ || Object.getPrototypeOf(Progress)).call.apply(_ref, [this].concat(args))), _this), _this.calculatePercent = function () {
      var _this$props = _this.props,
          percent = _this$props.percent,
          total = _this$props.total,
          value = _this$props.value;


      if (!_isUndefined(percent)) return percent;
      if (!_isUndefined(total) && !_isUndefined(value)) return value / total * 100;
    }, _this.getPercent = function () {
      var precision = _this.props.precision;

      var percent = _clamp(_this.calculatePercent(), 0, 100);

      if (_isUndefined(precision)) return percent;
      return _round(percent, precision);
    }, _this.isAutoSuccess = function () {
      var _this$props2 = _this.props,
          autoSuccess = _this$props2.autoSuccess,
          percent = _this$props2.percent,
          total = _this$props2.total,
          value = _this$props2.value;


      return autoSuccess && (percent >= 100 || value >= total);
    }, _this.renderLabel = function () {
      var _this$props3 = _this.props,
          children = _this$props3.children,
          label = _this$props3.label;


      if (!_isNil(children)) return React.createElement(
        'div',
        { className: 'label' },
        children
      );
      return createShorthand('div', function (val) {
        return { children: val };
      }, label, { className: 'label' });
    }, _this.renderProgress = function (percent) {
      var _this$props4 = _this.props,
          precision = _this$props4.precision,
          progress = _this$props4.progress,
          total = _this$props4.total,
          value = _this$props4.value;


      if (!progress && _isUndefined(precision)) return;
      return React.createElement(
        'div',
        { className: 'progress' },
        progress !== 'ratio' ? percent + '%' : value + '/' + total
      );
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Progress, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          attached = _props.attached,
          className = _props.className,
          color = _props.color,
          disabled = _props.disabled,
          error = _props.error,
          indicating = _props.indicating,
          inverted = _props.inverted,
          size = _props.size,
          success = _props.success,
          warning = _props.warning;


      var classes = cx('ui', color, size, useKeyOnly(active || indicating, 'active'), useKeyOnly(disabled, 'disabled'), useKeyOnly(error, 'error'), useKeyOnly(indicating, 'indicating'), useKeyOnly(inverted, 'inverted'), useKeyOnly(success || this.isAutoSuccess(), 'success'), useKeyOnly(warning, 'warning'), useValueAndKey(attached, 'attached'), 'progress', className);
      var rest = getUnhandledProps(Progress, this.props);
      var ElementType = getElementType(Progress, this.props);
      var percent = this.getPercent();

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes }),
        React.createElement(
          'div',
          { className: 'bar', style: { width: percent + '%' } },
          this.renderProgress(percent)
        ),
        this.renderLabel()
      );
    }
  }]);

  return Progress;
}(Component);

Progress._meta = {
  name: 'Progress',
  type: META.TYPES.MODULE
};
process.env.NODE_ENV !== "production" ? Progress.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A progress bar can show activity. */
  active: PropTypes.bool,

  /** A progress bar can attach to and show the progress of an element (i.e. Card or Segment). */
  attached: PropTypes.oneOf(['top', 'bottom']),

  /** Whether success state should automatically trigger when progress completes. */
  autoSuccess: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A progress bar can have different colors. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** A progress bar be disabled. */
  disabled: PropTypes.bool,

  /** A progress bar can show a error state. */
  error: PropTypes.bool,

  /** An indicating progress bar visually indicates the current level of progress of a task. */
  indicating: PropTypes.bool,

  /** A progress bar can have its colors inverted. */
  inverted: PropTypes.bool,

  /** Can be set to either to display progress as percent or ratio. */
  label: customPropTypes.itemShorthand,

  /** Current percent complete. */
  percent: customPropTypes.every([customPropTypes.disallow(['total', 'value']), PropTypes.oneOfType([PropTypes.number, PropTypes.string])]),

  /** Decimal point precision for calculated progress. */
  precision: PropTypes.number,

  /** A progress bar can contain a text value indicating current progress. */
  progress: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['percent', 'ratio'])]),

  /** A progress bar can vary in size. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'mini', 'huge', 'massive')),

  /** A progress bar can show a success state. */
  success: PropTypes.bool,

  /**
   * For use with value.
   * Together, these will calculate the percent.
   * Mutually excludes percent.
   */
  total: customPropTypes.every([customPropTypes.demand(['value']), customPropTypes.disallow(['percent']), PropTypes.oneOfType([PropTypes.number, PropTypes.string])]),

  /**
   * For use with total. Together, these will calculate the percent. Mutually excludes percent.
   */
  value: customPropTypes.every([customPropTypes.demand(['total']), customPropTypes.disallow(['percent']), PropTypes.oneOfType([PropTypes.number, PropTypes.string])]),

  /** A progress bar can show a warning state. */
  warning: PropTypes.bool
} : void 0;
Progress.handledProps = ['active', 'as', 'attached', 'autoSuccess', 'children', 'className', 'color', 'disabled', 'error', 'indicating', 'inverted', 'label', 'percent', 'precision', 'progress', 'size', 'success', 'total', 'value', 'warning'];


export default Progress;