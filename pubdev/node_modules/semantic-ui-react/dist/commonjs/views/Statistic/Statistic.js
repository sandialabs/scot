'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _StatisticGroup = require('./StatisticGroup');

var _StatisticGroup2 = _interopRequireDefault(_StatisticGroup);

var _StatisticLabel = require('./StatisticLabel');

var _StatisticLabel2 = _interopRequireDefault(_StatisticLabel);

var _StatisticValue = require('./StatisticValue');

var _StatisticValue2 = _interopRequireDefault(_StatisticValue);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A statistic emphasizes the current value of an attribute.
 */
function Statistic(props) {
  var children = props.children,
      className = props.className,
      color = props.color,
      floated = props.floated,
      horizontal = props.horizontal,
      inverted = props.inverted,
      label = props.label,
      size = props.size,
      text = props.text,
      value = props.value;


  var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useValueAndKey)(floated, 'floated'), (0, _lib.useKeyOnly)(horizontal, 'horizontal'), (0, _lib.useKeyOnly)(inverted, 'inverted'), 'statistic', className);
  var rest = (0, _lib.getUnhandledProps)(Statistic, props);
  var ElementType = (0, _lib.getElementType)(Statistic, props);

  if (!(0, _isNil3.default)(children)) return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    _react2.default.createElement(_StatisticValue2.default, { text: text, value: value }),
    _react2.default.createElement(_StatisticLabel2.default, { label: label })
  );
}

Statistic.handledProps = ['as', 'children', 'className', 'color', 'floated', 'horizontal', 'inverted', 'label', 'size', 'text', 'value'];
Statistic._meta = {
  name: 'Statistic',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? Statistic.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A statistic can be formatted to be different colors. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** A statistic can sit to the left or right of other content. */
  floated: _react.PropTypes.oneOf(_lib.SUI.FLOATS),

  /** A statistic can present its measurement horizontally. */
  horizontal: _react.PropTypes.bool,

  /** A statistic can be formatted to fit on a dark background. */
  inverted: _react.PropTypes.bool,

  /** Label content of the Statistic. */
  label: _lib.customPropTypes.contentShorthand,

  /** A statistic can vary in size. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'big', 'massive', 'medium')),

  /** Format the StatisticValue with smaller font size to fit nicely beside number values. */
  text: _react.PropTypes.bool,

  /** Value content of the Statistic. */
  value: _lib.customPropTypes.contentShorthand
} : void 0;

Statistic.Group = _StatisticGroup2.default;
Statistic.Label = _StatisticLabel2.default;
Statistic.Value = _StatisticValue2.default;

exports.default = Statistic;