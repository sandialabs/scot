'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _class, _temp; /**
                    * @copyright 2015, Andrey Popp <8mayday@gmail.com>
                    */

var _moment = require('moment');

var _moment2 = _interopRequireDefault(_moment);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Time = (_temp = _class = function (_React$Component) {
  _inherits(Time, _React$Component);

  function Time() {
    _classCallCheck(this, Time);

    return _possibleConstructorReturn(this, Object.getPrototypeOf(Time).apply(this, arguments));
  }

  _createClass(Time, [{
    key: 'render',
    value: function render() {
      var _props = this.props;
      var value = _props.value;
      var locale = _props.locale;
      var relative = _props.relative;
      var utc = _props.utc;
      var format = _props.format;
      var valueFormat = _props.valueFormat;
      var titleFormat = _props.titleFormat;
      var Component = _props.Component;

      var props = _objectWithoutProperties(_props, ['value', 'locale', 'relative', 'utc', 'format', 'valueFormat', 'titleFormat', 'Component']);

      if (!value) {
        return _react2.default.createElement(
          'span',
          null,
          'Invalid date'
        );
      }

      if (!_moment2.default.isMoment(value)) {
        value = (0, _moment2.default)(value, valueFormat, true);
      }

      if (locale) {
        value = value.locale(locale);
      }

      if (utc) {
        value = value.utc();
      }

      var machineReadable = value.format('YYYY-MM-DDTHH:mm:ssZ');

      if (relative || format) {
        var humanReadable = relative ? value.fromNow() : value.format(format);
        return _react2.default.createElement(
          Component,
          _extends({
            title: relative ? value.format(titleFormat) : null
          }, props, {
            dateTime: machineReadable }),
          humanReadable
        );
      } else {
        return _react2.default.createElement(
          'time',
          props,
          machineReadable
        );
      }
    }
  }]);

  return Time;
}(_react2.default.Component), _class.propTypes = {

  /**
   * Value.
   */
  value: _react.PropTypes.oneOfType([_react.PropTypes.instanceOf(_moment2.default.fn.constructor), _react.PropTypes.instanceOf(Date), _react.PropTypes.number, _react.PropTypes.string]).isRequired,

  /**
   * If component should output the relative time difference between now and
   * passed value.
   */
  relative: _react.PropTypes.bool,

  /**
   * If set to true will use the utc mode from moment and display all dates
   * in utc disregarding the users locale
   */
  utc: _react.PropTypes.bool,

  /**
   * Datetime format which is used to output date to DOM.
   */
  format: _react.PropTypes.string,

  /**
   * Datetime format which is used to parse value if it's being a string.
   */
  valueFormat: _react.PropTypes.string,

  /**
   * Datetime format which is used to set title attribute on relative or
   * formatted dates.
   */
  titleFormat: _react.PropTypes.string,

  /**
   * Locale.
   */
  locale: _react.PropTypes.string,

  /**
   * Component to use.
   */
  Component: _react.PropTypes.oneOfType([_react.PropTypes.string, _react.PropTypes.func])
}, _class.defaultProps = {
  titleFormat: 'YYYY-MM-DD HH:mm',
  Component: 'time'
}, _temp);
exports.default = Time;
