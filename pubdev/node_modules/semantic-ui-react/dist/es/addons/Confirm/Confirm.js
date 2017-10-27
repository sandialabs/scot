import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _has from 'lodash/has';

import React, { Component, PropTypes } from 'react';

import { customPropTypes, getUnhandledProps, META } from '../../lib';
import Button from '../../elements/Button';
import Modal from '../../modules/Modal';

/**
 * A Confirm modal gives the user a choice to confirm or cancel an action/
 * @see Modal
 */

var Confirm = function (_Component) {
  _inherits(Confirm, _Component);

  function Confirm() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Confirm);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Confirm.__proto__ || Object.getPrototypeOf(Confirm)).call.apply(_ref, [this].concat(args))), _this), _this.handleCancel = function (e) {
      var onCancel = _this.props.onCancel;


      if (onCancel) onCancel(e, _this.props);
    }, _this.handleConfirm = function (e) {
      var onConfirm = _this.props.onConfirm;


      if (onConfirm) onConfirm(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Confirm, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          cancelButton = _props.cancelButton,
          confirmButton = _props.confirmButton,
          content = _props.content,
          header = _props.header,
          open = _props.open;

      var rest = getUnhandledProps(Confirm, this.props);

      // `open` is auto controlled by the Modal
      // It cannot be present (even undefined) with `defaultOpen`
      // only apply it if the user provided an open prop
      var openProp = {};
      if (_has(this.props, 'open')) openProp.open = open;

      return React.createElement(
        Modal,
        _extends({}, rest, openProp, { size: 'small', onClose: this.handleCancel }),
        Modal.Header.create(header),
        Modal.Content.create(content),
        React.createElement(
          Modal.Actions,
          null,
          Button.create(cancelButton, { onClick: this.handleCancel }),
          Button.create(confirmButton, {
            onClick: this.handleConfirm,
            primary: true
          })
        )
      );
    }
  }]);

  return Confirm;
}(Component);

Confirm.defaultProps = {
  cancelButton: 'Cancel',
  confirmButton: 'OK',
  content: 'Are you sure?'
};
Confirm._meta = {
  name: 'Confirm',
  type: META.TYPES.ADDON
};
process.env.NODE_ENV !== "production" ? Confirm.propTypes = {
  /** The cancel button text. */
  cancelButton: customPropTypes.itemShorthand,

  /** The OK button text. */
  confirmButton: customPropTypes.itemShorthand,

  /** The ModalContent text. */
  content: customPropTypes.itemShorthand,

  /** The ModalHeader text. */
  header: customPropTypes.itemShorthand,

  /**
   * Called when the Modal is closed without clicking confirm.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onCancel: PropTypes.func,

  /**
   * Called when the OK button is clicked.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onConfirm: PropTypes.func,

  /** Whether or not the modal is visible. */
  open: PropTypes.bool
} : void 0;
Confirm.handledProps = ['cancelButton', 'confirmButton', 'content', 'header', 'onCancel', 'onConfirm', 'open'];


export default Confirm;