'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A group of images.
 */
function ImageGroup(props) {
  var children = props.children,
      className = props.className,
      size = props.size;

  var classes = (0, _classnames2.default)('ui', size, className, 'images');
  var rest = (0, _lib.getUnhandledProps)(ImageGroup, props);
  var ElementType = (0, _lib.getElementType)(ImageGroup, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    children
  );
}

ImageGroup.handledProps = ['as', 'children', 'className', 'size'];
ImageGroup._meta = {
  name: 'ImageGroup',
  parent: 'Image',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ImageGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A group of images can be formatted to have the same size. */
  size: _react.PropTypes.oneOf(_lib.SUI.SIZES)
} : void 0;

exports.default = ImageGroup;