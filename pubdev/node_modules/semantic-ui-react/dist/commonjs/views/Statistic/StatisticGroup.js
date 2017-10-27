'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _map2 = require('lodash/map');

var _map3 = _interopRequireDefault(_map2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Statistic = require('./Statistic');

var _Statistic2 = _interopRequireDefault(_Statistic);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A group of statistics.
 */
function StatisticGroup(props) {
  var children = props.children,
      className = props.className,
      color = props.color,
      horizontal = props.horizontal,
      inverted = props.inverted,
      items = props.items,
      size = props.size,
      widths = props.widths;


  var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useKeyOnly)(horizontal, 'horizontal'), (0, _lib.useKeyOnly)(inverted, 'inverted'), (0, _lib.useWidthProp)(widths), 'statistics', className);
  var rest = (0, _lib.getUnhandledProps)(StatisticGroup, props);
  var ElementType = (0, _lib.getElementType)(StatisticGroup, props);

  if (!(0, _isNil3.default)(children)) return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );

  var itemsJSX = (0, _map3.default)(items, function (item) {
    return _react2.default.createElement(_Statistic2.default, (0, _extends3.default)({ key: item.childKey || [item.label, item.title].join('-') }, item));
  });

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    itemsJSX
  );
}

StatisticGroup.handledProps = ['as', 'children', 'className', 'color', 'horizontal', 'inverted', 'items', 'size', 'widths'];
StatisticGroup._meta = {
  name: 'StatisticGroup',
  type: _lib.META.TYPES.VIEW,
  parent: 'Statistic'
};

process.env.NODE_ENV !== "production" ? StatisticGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A statistic group can be formatted to be different colors. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** A statistic group can present its measurement horizontally. */
  horizontal: _react.PropTypes.bool,

  /** A statistic group can be formatted to fit on a dark background. */
  inverted: _react.PropTypes.bool,

  /** Array of props for Statistic. */
  items: _lib.customPropTypes.collectionShorthand,

  /** A statistic group can vary in size. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'big', 'massive', 'medium')),

  /** A statistic group can have its items divided evenly. */
  widths: _react.PropTypes.oneOf(_lib.SUI.WIDTHS)
} : void 0;

exports.default = StatisticGroup;