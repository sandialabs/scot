'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A statistic can contain a label to help provide context for the presented value.
 */
function StatisticLabel(props) {
  var children = props.children,
      className = props.className,
      label = props.label;

  var classes = (0, _classnames2.default)('label', className);
  var rest = (0, _lib.getUnhandledProps)(StatisticLabel, props);
  var ElementType = (0, _lib.getElementType)(StatisticLabel, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? label : children
  );
}

StatisticLabel.handledProps = ['as', 'children', 'className', 'label'];
StatisticLabel._meta = {
  name: 'StatisticLabel',
  parent: 'Statistic',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? StatisticLabel.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  label: _lib.customPropTypes.contentShorthand
} : void 0;

exports.default = StatisticLabel;