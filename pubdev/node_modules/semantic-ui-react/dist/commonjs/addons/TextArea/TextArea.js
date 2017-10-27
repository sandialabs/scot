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

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A TextArea can be used to allow for extended user input.
 * @see Form
 */
var TextArea = function (_Component) {
  (0, _inherits3.default)(TextArea, _Component);

  function TextArea() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, TextArea);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = TextArea.__proto__ || Object.getPrototypeOf(TextArea)).call.apply(_ref, [this].concat(args))), _this), _this.handleChange = function (e) {
      var onChange = _this.props.onChange;

      if (onChange) onChange(e, (0, _extends3.default)({}, _this.props, { value: e.target && e.target.value }));

      _this.updateHeight(e.target);
    }, _this.handleRef = function (c) {
      return _this.ref = c;
    }, _this.removeAutoHeightStyles = function () {
      _this.ref.removeAttribute('rows');
      _this.ref.style.height = null;
      _this.ref.style.minHeight = null;
      _this.ref.style.resize = null;
    }, _this.updateHeight = function () {
      if (!_this.ref) return;

      var autoHeight = _this.props.autoHeight;

      if (!autoHeight) return;

      var _window$getComputedSt = window.getComputedStyle(_this.ref),
          borderTopWidth = _window$getComputedSt.borderTopWidth,
          borderBottomWidth = _window$getComputedSt.borderBottomWidth;

      borderTopWidth = parseInt(borderTopWidth, 10);
      borderBottomWidth = parseInt(borderBottomWidth, 10);

      _this.ref.rows = '1';
      _this.ref.style.minHeight = '0';
      _this.ref.style.resize = 'none';
      _this.ref.style.height = 'auto';
      _this.ref.style.height = _this.ref.scrollHeight + borderTopWidth + borderBottomWidth + 'px';
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(TextArea, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      this.updateHeight();
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate(prevProps, prevState) {
      // removed autoHeight
      if (!this.props.autoHeight && prevProps.autoHeight) {
        this.removeAutoHeightStyles();
      }
      // added autoHeight or value changed
      if (this.props.autoHeight && !prevProps.autoHeight || prevProps.value !== this.props.value) {
        this.updateHeight();
      }
    }
  }, {
    key: 'render',
    value: function render() {
      var value = this.props.value;

      var rest = (0, _lib.getUnhandledProps)(TextArea, this.props);
      var ElementType = (0, _lib.getElementType)(TextArea, this.props);

      return _react2.default.createElement(ElementType, (0, _extends3.default)({}, rest, { onChange: this.handleChange, ref: this.handleRef, value: value }));
    }
  }]);
  return TextArea;
}(_react.Component);

TextArea._meta = {
  name: 'TextArea',
  type: _lib.META.TYPES.ADDON
};
TextArea.defaultProps = {
  as: 'textarea'
};
process.env.NODE_ENV !== "production" ? TextArea.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Indicates whether height of the textarea fits the content or not. */
  autoHeight: _react.PropTypes.bool,

  /**
   * Called on change.
   * @param {SyntheticEvent} event - The React SyntheticEvent object
   * @param {object} data - All props and the event value.
   */
  onChange: _react.PropTypes.func,

  /** The value of the textarea. */
  value: _react.PropTypes.string
} : void 0;
TextArea.handledProps = ['as', 'autoHeight', 'onChange', 'value'];
exports.default = TextArea;