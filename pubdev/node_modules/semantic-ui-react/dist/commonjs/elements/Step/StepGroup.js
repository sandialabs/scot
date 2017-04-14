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

var _Step = require('./Step');

var _Step2 = _interopRequireDefault(_Step);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A set of steps.
 */
function StepGroup(props) {
  var children = props.children,
      className = props.className,
      fluid = props.fluid,
      items = props.items,
      ordered = props.ordered,
      size = props.size,
      stackable = props.stackable,
      vertical = props.vertical;

  var classes = (0, _classnames2.default)('ui', size, (0, _lib.useKeyOnly)(fluid, 'fluid'), (0, _lib.useKeyOnly)(ordered, 'ordered'), (0, _lib.useKeyOnly)(vertical, 'vertical'), (0, _lib.useValueAndKey)(stackable, 'stackable'), 'steps', className);
  var rest = (0, _lib.getUnhandledProps)(StepGroup, props);
  var ElementType = (0, _lib.getElementType)(StepGroup, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  var content = (0, _map3.default)(items, function (item) {
    var key = item.key || [item.title, item.description].join('-');
    return _react2.default.createElement(_Step2.default, (0, _extends3.default)({ key: key }, item));
  });

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    content
  );
}

StepGroup.handledProps = ['as', 'children', 'className', 'fluid', 'items', 'ordered', 'size', 'stackable', 'vertical'];
StepGroup._meta = {
  name: 'StepGroup',
  parent: 'Step',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? StepGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A fluid step takes up the width of its container. */
  fluid: _react.PropTypes.bool,

  /** Shorthand array of props for Step. */
  items: _lib.customPropTypes.collectionShorthand,

  /** A step can show a ordered sequence of steps. */
  ordered: _react.PropTypes.bool,

  /** Steps can have different sizes. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'medium')),

  /** A step can stack vertically only on smaller screens. */
  stackable: _react.PropTypes.oneOf(['tablet']),

  /** A step can be displayed stacked vertically. */
  vertical: _react.PropTypes.bool
} : void 0;

exports.default = StepGroup;