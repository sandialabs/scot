'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Checkbox = require('../../modules/Checkbox');

var _Checkbox2 = _interopRequireDefault(_Checkbox);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A Radio is sugar for <Checkbox radio />.
 * Useful for exclusive groups of sliders or toggles.
 * @see Checkbox
 * @see Form
 */
function Radio(props) {
  var slider = props.slider,
      toggle = props.toggle,
      type = props.type;

  var rest = (0, _lib.getUnhandledProps)(Radio, props);
  // const ElementType = getElementType(Radio, props)
  // radio, slider, toggle are exclusive
  // use an undefined radio if slider or toggle are present
  var radio = !(slider || toggle) || undefined;

  return _react2.default.createElement(_Checkbox2.default, (0, _extends3.default)({}, rest, { type: type, radio: radio, slider: slider, toggle: toggle }));
}

Radio.handledProps = ['slider', 'toggle', 'type'];
Radio._meta = {
  name: 'Radio',
  type: _lib.META.TYPES.ADDON
};

process.env.NODE_ENV !== "production" ? Radio.propTypes = {
  /** Format to emphasize the current selection state. */
  slider: _Checkbox2.default.propTypes.slider,

  /** Format to show an on or off choice. */
  toggle: _Checkbox2.default.propTypes.toggle,

  /** HTML input type, either checkbox or radio. */
  type: _Checkbox2.default.propTypes.type
} : void 0;

Radio.defaultProps = {
  type: 'radio'
};

exports.default = Radio;