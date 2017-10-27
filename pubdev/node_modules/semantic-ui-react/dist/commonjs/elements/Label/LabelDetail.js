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

function LabelDetail(props) {
  var children = props.children,
      className = props.className,
      content = props.content;

  var classes = (0, _classnames2.default)('detail', className);
  var rest = (0, _lib.getUnhandledProps)(LabelDetail, props);
  var ElementType = (0, _lib.getElementType)(LabelDetail, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? content : children
  );
}

LabelDetail.handledProps = ['as', 'children', 'className', 'content'];
LabelDetail._meta = {
  name: 'LabelDetail',
  parent: 'Label',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? LabelDetail.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand
} : void 0;

exports.default = LabelDetail;