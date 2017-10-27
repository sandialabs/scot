'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _round2 = require('lodash/round');

var _round3 = _interopRequireDefault(_round2);

var _clamp2 = require('lodash/clamp');

var _clamp3 = _interopRequireDefault(_clamp2);

var _isUndefined2 = require('lodash/isUndefined');

var _isUndefined3 = _interopRequireDefault(_isUndefined2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A progress bar shows the progression of a task.
 */
var Progress = function (_Component) {
  (0, _inherits3.default)(Progress, _Component);

  function Progress() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Progress);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Progress.__proto__ || Object.getPrototypeOf(Progress)).call.apply(_ref, [this].concat(args))), _this), _this.calculatePercent = function () {
      var _this$props = _this.props,
          percent = _this$props.percent,
          total = _this$props.total,
          value = _this$props.value;


      if (!(0, _isUndefined3.default)(percent)) return percent;
      if (!(0, _isUndefined3.default)(total) && !(0, _isUndefined3.default)(value)) return value / total * 100;
    }, _this.getPercent = function () {
      var precision = _this.props.precision;

      var percent = (0, _clamp3.default)(_this.calculatePercent(), 0, 100);

      if ((0, _isUndefined3.default)(precision)) return percent;
      return (0, _round3.default)(percent, precision);
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


      if (!(0, _isNil3.default)(children)) return _react2.default.createElement(
        'div',
        { className: 'label' },
        children
      );
      return (0, _lib.createShorthand)('div', function (val) {
        return { children: val };
      }, label, { className: 'label' });
    }, _this.renderProgress = function (percent) {
      var _this$props4 = _this.props,
          precision = _this$props4.precision,
          progress = _this$props4.progress,
          total = _this$props4.total,
          value = _this$props4.value;


      if (!progress && (0, _isUndefined3.default)(precision)) return;
      return _react2.default.createElement(
        'div',
        { className: 'progress' },
        progress !== 'ratio' ? percent + '%' : value + '/' + total
      );
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Progress, [{
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


      var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useKeyOnly)(active || indicating, 'active'), (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(error, 'error'), (0, _lib.useKeyOnly)(indicating, 'indicating'), (0, _lib.useKeyOnly)(inverted, 'inverted'), (0, _lib.useKeyOnly)(success || this.isAutoSuccess(), 'success'), (0, _lib.useKeyOnly)(warning, 'warning'), (0, _lib.useValueAndKey)(attached, 'attached'), 'progress', className);
      var rest = (0, _lib.getUnhandledProps)(Progress, this.props);
      var ElementType = (0, _lib.getElementType)(Progress, this.props);
      var percent = this.getPercent();

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes }),
        _react2.default.createElement(
          'div',
          { className: 'bar', style: { width: percent + '%' } },
          this.renderProgress(percent)
        ),
        this.renderLabel()
      );
    }
  }]);
  return Progress;
}(_react.Component);

Progress._meta = {
  name: 'Progress',
  type: _lib.META.TYPES.MODULE
};
process.env.NODE_ENV !== "production" ? Progress.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A progress bar can show activity. */
  active: _react.PropTypes.bool,

  /** A progress bar can attach to and show the progress of an element (i.e. Card or Segment). */
  attached: _react.PropTypes.oneOf(['top', 'bottom']),

  /** Whether success state should automatically trigger when progress completes. */
  autoSuccess: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A progress bar can have different colors. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** A progress bar be disabled. */
  disabled: _react.PropTypes.bool,

  /** A progress bar can show a error state. */
  error: _react.PropTypes.bool,

  /** An indicating progress bar visually indicates the current level of progress of a task. */
  indicating: _react.PropTypes.bool,

  /** A progress bar can have its colors inverted. */
  inverted: _react.PropTypes.bool,

  /** Can be set to either to display progress as percent or ratio. */
  label: _lib.customPropTypes.itemShorthand,

  /** Current percent complete. */
  percent: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['total', 'value']), _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string])]),

  /** Decimal point precision for calculated progress. */
  precision: _react.PropTypes.number,

  /** A progress bar can contain a text value indicating current progress. */
  progress: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['percent', 'ratio'])]),

  /** A progress bar can vary in size. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'mini', 'huge', 'massive')),

  /** A progress bar can show a success state. */
  success: _react.PropTypes.bool,

  /**
   * For use with value.
   * Together, these will calculate the percent.
   * Mutually excludes percent.
   */
  total: _lib.customPropTypes.every([_lib.customPropTypes.demand(['value']), _lib.customPropTypes.disallow(['percent']), _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string])]),

  /**
   * For use with total. Together, these will calculate the percent. Mutually excludes percent.
   */
  value: _lib.customPropTypes.every([_lib.customPropTypes.demand(['total']), _lib.customPropTypes.disallow(['percent']), _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string])]),

  /** A progress bar can show a warning state. */
  warning: _react.PropTypes.bool
} : void 0;
Progress.handledProps = ['active', 'as', 'attached', 'autoSuccess', 'children', 'className', 'color', 'disabled', 'error', 'indicating', 'inverted', 'label', 'percent', 'precision', 'progress', 'size', 'success', 'total', 'value', 'warning'];
exports.default = Progress;