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

var _has2 = require('lodash/has');

var _has3 = _interopRequireDefault(_has2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Button = require('../../elements/Button');

var _Button2 = _interopRequireDefault(_Button);

var _Modal = require('../../modules/Modal');

var _Modal2 = _interopRequireDefault(_Modal);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A Confirm modal gives the user a choice to confirm or cancel an action/
 * @see Modal
 */
var Confirm = function (_Component) {
  (0, _inherits3.default)(Confirm, _Component);

  function Confirm() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Confirm);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Confirm.__proto__ || Object.getPrototypeOf(Confirm)).call.apply(_ref, [this].concat(args))), _this), _this.handleCancel = function (e) {
      var onCancel = _this.props.onCancel;


      if (onCancel) onCancel(e, _this.props);
    }, _this.handleConfirm = function (e) {
      var onConfirm = _this.props.onConfirm;


      if (onConfirm) onConfirm(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Confirm, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          cancelButton = _props.cancelButton,
          confirmButton = _props.confirmButton,
          content = _props.content,
          header = _props.header,
          open = _props.open;

      var rest = (0, _lib.getUnhandledProps)(Confirm, this.props);

      // `open` is auto controlled by the Modal
      // It cannot be present (even undefined) with `defaultOpen`
      // only apply it if the user provided an open prop
      var openProp = {};
      if ((0, _has3.default)(this.props, 'open')) openProp.open = open;

      return _react2.default.createElement(
        _Modal2.default,
        (0, _extends3.default)({}, rest, openProp, { size: 'small', onClose: this.handleCancel }),
        _Modal2.default.Header.create(header),
        _Modal2.default.Content.create(content),
        _react2.default.createElement(
          _Modal2.default.Actions,
          null,
          _Button2.default.create(cancelButton, { onClick: this.handleCancel }),
          _Button2.default.create(confirmButton, {
            onClick: this.handleConfirm,
            primary: true
          })
        )
      );
    }
  }]);
  return Confirm;
}(_react.Component);

Confirm.defaultProps = {
  cancelButton: 'Cancel',
  confirmButton: 'OK',
  content: 'Are you sure?'
};
Confirm._meta = {
  name: 'Confirm',
  type: _lib.META.TYPES.ADDON
};
process.env.NODE_ENV !== "production" ? Confirm.propTypes = {
  /** The cancel button text. */
  cancelButton: _lib.customPropTypes.itemShorthand,

  /** The OK button text. */
  confirmButton: _lib.customPropTypes.itemShorthand,

  /** The ModalContent text. */
  content: _lib.customPropTypes.itemShorthand,

  /** The ModalHeader text. */
  header: _lib.customPropTypes.itemShorthand,

  /**
   * Called when the Modal is closed without clicking confirm.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onCancel: _react.PropTypes.func,

  /**
   * Called when the OK button is clicked.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onConfirm: _react.PropTypes.func,

  /** Whether or not the modal is visible. */
  open: _react.PropTypes.bool
} : void 0;
Confirm.handledProps = ['cancelButton', 'confirmButton', 'content', 'header', 'onCancel', 'onConfirm', 'open'];
exports.default = Confirm;