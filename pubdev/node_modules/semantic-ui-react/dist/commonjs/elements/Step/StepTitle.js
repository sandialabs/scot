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
 * A step can contain a title.
 */
function StepTitle(props) {
  var children = props.children,
      className = props.className,
      title = props.title;

  var classes = (0, _classnames2.default)('title', className);
  var rest = (0, _lib.getUnhandledProps)(StepTitle, props);
  var ElementType = (0, _lib.getElementType)(StepTitle, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? title : children
  );
}

StepTitle.handledProps = ['as', 'children', 'className', 'title'];
StepTitle._meta = {
  name: 'StepTitle',
  parent: 'Step',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? StepTitle.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Shorthand for primary content. */
  title: _lib.customPropTypes.contentShorthand
} : void 0;

exports.default = StepTitle;