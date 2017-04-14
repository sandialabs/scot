'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Image = require('../../elements/Image');

var _Image2 = _interopRequireDefault(_Image);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * An item can contain an image.
 */
function ItemImage(props) {
  var size = props.size;

  var rest = (0, _lib.getUnhandledProps)(ItemImage, props);

  return _react2.default.createElement(_Image2.default, (0, _extends3.default)({}, rest, { size: size, ui: !!size, wrapped: true }));
}

ItemImage.handledProps = ['size'];
ItemImage._meta = {
  name: 'ItemImage',
  parent: 'Item',
  type: _lib.META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? ItemImage.propTypes = {
  /** An image may appear at different sizes. */
  size: _Image2.default.propTypes.size
} : void 0;

ItemImage.create = (0, _lib.createShorthandFactory)(ItemImage, function (src) {
  return { src: src };
});

exports.default = ItemImage;