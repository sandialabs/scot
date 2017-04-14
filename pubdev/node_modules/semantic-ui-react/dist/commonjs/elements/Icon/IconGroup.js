'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Several icons can be used together as a group.
 */
function IconGroup(props) {
  var children = props.children,
      className = props.className,
      size = props.size;

  var classes = (0, _classnames2.default)(size, 'icons', className);
  var rest = (0, _lib.getUnhandledProps)(IconGroup, props);
  var ElementType = (0, _lib.getElementType)(IconGroup, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

IconGroup.handledProps = ['as', 'children', 'className', 'size'];
IconGroup._meta = {
  name: 'IconGroup',
  parent: 'Icon',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? IconGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Size of the icon group. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'medium'))
} : void 0;

IconGroup.defaultProps = {
  as: 'i'
};

exports.default = IconGroup;