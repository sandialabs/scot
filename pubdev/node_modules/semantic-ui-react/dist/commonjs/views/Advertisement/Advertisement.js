'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * An ad displays third-party promotional content.
 */
function Advertisement(props) {
  var centered = props.centered,
      children = props.children,
      className = props.className,
      test = props.test,
      unit = props.unit;


  var classes = (0, _classnames2.default)('ui', unit, (0, _lib.useKeyOnly)(centered, 'centered'), (0, _lib.useKeyOnly)(test, 'test'), 'ad', className);
  var rest = (0, _lib.getUnhandledProps)(Advertisement, props);
  var ElementType = (0, _lib.getElementType)(Advertisement, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes, 'data-text': test }),
    children
  );
}

Advertisement.handledProps = ['as', 'centered', 'children', 'className', 'test', 'unit'];
Advertisement._meta = {
  name: 'Advertisement',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? Advertisement.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Center the advertisement. */
  centered: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Text to be displayed on the advertisement. */
  test: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.number, _react.PropTypes.string]),

  /** Varies the size of the advertisement. */
  unit: _react.PropTypes.oneOf(['medium rectangle', 'large rectangle', 'vertical rectangle', 'small rectangle', 'mobile banner', 'banner', 'vertical banner', 'top banner', 'half banner', 'button', 'square button', 'small button', 'skyscraper', 'wide skyscraper', 'leaderboard', 'large leaderboard', 'mobile leaderboard', 'billboard', 'panorama', 'netboard', 'half page', 'square', 'small square']).isRequired

} : void 0;

exports.default = Advertisement;